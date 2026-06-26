using Barotrauma;
using Barotrauma.Items.Components;
using HarmonyLib;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;
using System;
using System.Collections.Generic;
using System.Linq;

namespace NTCeHUDAutoMod.AC6TargetingHUDAuto
{
    public class AC6TargetingHUDAuto : IAssemblyPlugin
    {
        public static Harmony harmony;
        public static bool LockModeEnabled { get; set; } = false;
        public static Character LockedTarget => lockedTarget;
        public static bool IsLocked => lockedTarget != null && lockProgress >= 1f;

        public static bool MultiTargetMode { get; private set; } = false;
        public static IReadOnlyList<Character> SortedEnemies => sortedEnemiesList;
        private static readonly List<Character> sortedEnemiesList = new List<Character>(16);
        private static int multiTargetIndex = 0;

        private static Character lockedTarget = null;
        private static float lockProgress = 0f;
        private static readonly List<Character> visibleEnemies = new List<Character>(16);
        private static float enemyUpdateTimer = 0f;
        private static readonly List<(Character character, float distSq)> tempSortList = new List<(Character, float)>(16);

        public static Turret ActiveTurret { get; private set; } = null;
        public static Controller ActiveController { get; private set; } = null;
        public static bool IsTurretMode => ActiveTurret != null && ActiveController != null;

        private const float LockTime = 0.15f;
        private const float MaxLockRange = 2000f;
        private const float MaxLockRangeSq = MaxLockRange * MaxLockRange;
        private const float TurretMaxLockRange = 3500f;
        private const float TurretMaxLockRangeSq = TurretMaxLockRange * TurretMaxLockRange;
        private const float EnemyUpdateInterval = 0.2f;
        private const float SameHullBonus = 800f;
        private const float PixelsPerMeter = 100f;
        private const float ObstructedPenalty = 600f;

        private static readonly Color CircleColor = new Color(100, 110, 120, 140);
        private static readonly Color CrosshairColor = new Color(80, 170, 210, 255);
        private static readonly Color CornerArcColor = new Color(140, 150, 160, 180);
        private static readonly Color LockedFrameColor = new Color(140, 150, 160, 200);
        private static readonly Color LockMarkerColor = new Color(190, 55, 75, 255);
        private static readonly Color AmmoArcBg = new Color(50, 55, 60, 80);
        private static readonly Color AmmoArcFill = new Color(150, 160, 170, 200);
        private static readonly Color DistanceColor = new Color(220, 225, 230, 255);
        private static readonly Color TickColor = new Color(120, 130, 140, 180);
        private static readonly Color MultiTargetFrameColor = new Color(180, 140, 60, 200);
        private static readonly Color MultiTargetIndexColor = new Color(255, 200, 80, 255);

        private const float OuterR = 130f;
        private const float InnerR = 120f;
        private const float CrossLen = 30f;
        private const float CrossGap = 10f;
        private const float CornerArcR = 160f;
        private const float CornerArcSpan = 55f;
        private const float CornerCapLen = 8f;
        private const float AmmoArcR = 125f;
        private const float AmmoArcW = 8f;
        private const float TickLen = 6f;

        private const float LockOuterR = 150f;
        private const float LockArcW = 18f;
        private const float LockMiddleR = 120f;
        private const float LockMarkerR = 50f;

        private static float cachedLeftAmmo = 1f;
        private static float cachedRightAmmo = 0f;
        private static float ammoUpdateTimer = 0f;
        private const float AmmoUpdateInterval = 0.1f;

        public void Initialize() => harmony = new Harmony("set.ac6targeting");

        public void OnLoadCompleted()
        {
            harmony?.PatchAll();
            GameMain.LuaCs.Hook.Add("think", "AC6TargetingUpdate", UpdateTargeting);
            GameMain.LuaCs.Hook.Add("ac6.getState", "AC6GetState", GetAC6State);
            GameMain.LuaCs.Hook.Add("ac6.getNextTarget", "AC6GetNextTarget", GetNextTargetForLua);
        }

        public static object[] GetAC6State(object[] args)
        {
            return new object[] { LockModeEnabled, IsLocked, MultiTargetMode, lockedTarget };
        }

        public static object[] GetNextTargetForLua(object[] args)
        {
            return new object[] { GetNextMultiTarget() };
        }

        public void Dispose()
        {
            harmony?.UnpatchSelf();
            ClearLock();
            ClearTurretState();
            visibleEnemies.Clear();
            sortedEnemiesList.Clear();
            LockModeEnabled = false;
            MultiTargetMode = false;
            multiTargetIndex = 0;
        }

        public void PreInitPatching() { }

        public static Character GetNextMultiTarget()
        {
            if (!MultiTargetMode || sortedEnemiesList.Count == 0) return null;
            if (multiTargetIndex >= sortedEnemiesList.Count) multiTargetIndex = 0;
            var target = sortedEnemiesList[multiTargetIndex];
            multiTargetIndex++;
            return target;
        }

        public static void ResetMultiTargetIndex()
        {
            multiTargetIndex = 0;
        }

        public static int GetMultiTargetCount()
        {
            return sortedEnemiesList.Count;
        }

        private static void ClearTurretState()
        {
            ActiveTurret = null;
            ActiveController = null;
        }

        private static void UpdateTurretState(Character character)
        {
            ActiveTurret = null;
            ActiveController = null;

            var selectedItem = character.SelectedItem;
            if (selectedItem == null) return;

            var controller = selectedItem.GetComponent<Controller>();
            if (controller == null) return;

            var focusTarget = controller.GetFocusTarget();
            if (focusTarget == null) return;

            var turret = focusTarget.GetComponent<Turret>();
            if (turret == null) return;

            ActiveController = controller;
            ActiveTurret = turret;
        }


        public static object[] UpdateTargeting(object[] args)
        {
            var character = Character.Controlled;
            if (character == null || character.IsDead)
            {
                if (LockModeEnabled)
                {
                    LockModeEnabled = false;
                    ClearLock();
                    ClearTurretState();
                    MultiTargetMode = false;
                    sortedEnemiesList.Clear();
                }
                return null;
            }

            if (!TechCrosshairHUDAuto.TechCrosshairHUDAuto.ShouldEnableHUD())
            {
                if (LockModeEnabled)
                {
                    LockModeEnabled = false;
                    ClearLock();
                    ClearTurretState();
                    MultiTargetMode = false;
                    sortedEnemiesList.Clear();
                }
                return null;
            }

            if (!LockModeEnabled) return null;

            UpdateTurretState(character);

            if (GUI.PauseMenuOpen || GUI.SettingsMenuOpen)
            {
                return null;
            }

            bool leftAltHeld = PlayerInput.KeyDown(Keys.LeftAlt);
            bool wasMultiTarget = MultiTargetMode;
            MultiTargetMode = leftAltHeld;

            if (MultiTargetMode && !wasMultiTarget)
            {
                multiTargetIndex = 0;
            }

            enemyUpdateTimer += (float)Timing.Step;
            if (enemyUpdateTimer >= EnemyUpdateInterval)
            {
                enemyUpdateTimer = 0f;
                UpdateVisibleEnemies(character);

                if (MultiTargetMode)
                {
                    UpdateSortedEnemies(character);
                }
            }

            if (MultiTargetMode)
            {
                return null;
            }

            bool isAiming = character.IsKeyDown(InputType.Aim);

            if (IsTurretMode)
            {
                if (!character.IsAnySelectedItem(ActiveController?.Item))
                {
                    ClearTurretState();
                    return null;
                }
                UpdateLockOn(character);
            }
            else
            {
                if (!isAiming)
                {
                    ClearLock();
                    return null;
                }
                UpdateLockOn(character);
                ApplyAutoAim(character);
            }

            return null;
        }

        private static void UpdateSortedEnemies(Character player)
        {
            sortedEnemiesList.Clear();
            Vector2 sourcePos = IsTurretMode ? GetTurretWorldPosition() : player.WorldPosition;

            tempSortList.Clear();

            for (int i = 0; i < visibleEnemies.Count; i++)
            {
                var e = visibleEnemies[i];
                if (e == null || e.Removed || e.IsDead || e.IsIncapacitated) continue;
                float distSq = Vector2.DistanceSquared(sourcePos, e.WorldPosition);
                tempSortList.Add((e, distSq));
            }

            tempSortList.Sort((a, b) => a.distSq.CompareTo(b.distSq));

            for (int i = 0; i < tempSortList.Count; i++)
            {
                sortedEnemiesList.Add(tempSortList[i].character);
            }
        }

        private static bool IsEnemy(Character player, Character other)
        {
            if (other.TeamID == CharacterTeamType.FriendlyNPC) return false;
            if (other.IsIncapacitated) return false;
            if (other.TeamID != player.TeamID) return true;
            if (other.AIController != null)
            {
                var aiType = other.AIController.GetType().Name;
                if (aiType.Contains("EnemyAI")) return true;
            }
            return false;
        }

        private static void UpdateVisibleEnemies(Character player)
        {
            visibleEnemies.Clear();
            var cam = Screen.Selected?.Cam;
            if (cam == null) return;

            Vector2 sourcePos = IsTurretMode ? GetTurretWorldPosition() : player.WorldPosition;
            float maxRangeSq = IsTurretMode ? TurretMaxLockRangeSq : MaxLockRangeSq;
            var resolution = cam.Resolution;
            float resX = resolution.X;
            float resY = resolution.Y;
            var charList = Character.CharacterList;

            for (int i = 0; i < charList.Count; i++)
            {
                var character = charList[i];
                if (character == null || character == player) continue;
                if (character.IsDead || !character.Enabled || character.Removed) continue;
                if (!IsEnemy(player, character)) continue;

                float distSq = Vector2.DistanceSquared(sourcePos, character.WorldPosition);
                if (distSq > maxRangeSq) continue;

                if (IsTurretMode && !IsWithinTurretRotationLimits(character.WorldPosition))
                    continue;

                var screenPos = cam.WorldToScreen(character.WorldPosition);
                if (screenPos.X >= 0 && screenPos.X <= resX &&
                    screenPos.Y >= 0 && screenPos.Y <= resY)
                {
                    visibleEnemies.Add(character);
                }
            }
        }

        private static Vector2 GetTurretWorldPosition()
        {
            if (ActiveTurret == null) return Vector2.Zero;
            var item = ActiveTurret.Item;
            return new Vector2(
                item.WorldRect.X + ActiveTurret.TransformedBarrelPos.X,
                item.WorldRect.Y - ActiveTurret.TransformedBarrelPos.Y);
        }

        private static bool IsWithinTurretRotationLimits(Vector2 targetPos)
        {
            if (ActiveTurret == null) return false;

            Vector2 turretPos = GetTurretWorldPosition();
            Vector2 diff = targetPos - turretPos;
            diff.Y = -diff.Y;
            float angle = MathUtils.WrapAngleTwoPi(MathUtils.VectorToAngle(diff));

            var limits = ActiveTurret.RotationLimits;
            float minRot = MathHelper.ToRadians(limits.X);
            float maxRot = MathHelper.ToRadians(limits.Y);

            minRot = MathUtils.WrapAngleTwoPi(minRot);
            maxRot = MathUtils.WrapAngleTwoPi(maxRot);

            if (minRot <= maxRot)
                return angle >= minRot && angle <= maxRot;
            else
                return angle >= minRot || angle <= maxRot;
        }

        private static void UpdateLockOn(Character player)
        {
            Character bestTarget = null;
            float bestScore = float.MaxValue;
            Hull playerHull = player.CurrentHull;
            Vector2 sourcePos = IsTurretMode ? GetTurretWorldPosition() : player.WorldPosition;

            for (int i = 0; i < visibleEnemies.Count; i++)
            {
                var enemy = visibleEnemies[i];
                if (enemy == null || enemy.Removed || enemy.IsDead || enemy.IsIncapacitated) continue;

                if (IsTurretMode && !IsWithinTurretRotationLimits(enemy.WorldPosition))
                    continue;

                float dist = Vector2.Distance(sourcePos, enemy.WorldPosition);
                float score = dist;
                if (playerHull != null && enemy.CurrentHull == playerHull)
                    score -= SameHullBonus;
                if (IsPathObstructed(player, enemy))
                    score += ObstructedPenalty;
                if (score < bestScore)
                {
                    bestScore = score;
                    bestTarget = enemy;
                }
            }

            if (bestTarget != null)
            {
                if (lockedTarget != bestTarget)
                {
                    lockedTarget = bestTarget;
                    lockProgress = 0f;
                }
                else
                {
                    lockProgress = Math.Min(lockProgress + (float)Timing.Step / LockTime, 1f);
                }
            }
            else
            {
                ClearLock();
            }
        }

        private static bool IsPathObstructed(Character player, Character target)
        {
            if (player.CurrentHull == null || target.CurrentHull == null) return false;
            if (player.CurrentHull == target.CurrentHull) return false;
            return true;
        }

        private static void ApplyAutoAim(Character player)
        {
            if (lockedTarget == null || lockedTarget.Removed || lockedTarget.IsDead) return;
            if (lockProgress < 1f) return;
            if (GUI.PauseMenuOpen || GUI.SettingsMenuOpen) return;

            var cam = Screen.Selected?.Cam;
            if (cam == null) return;

            if (IsTurretMode)
            {
                return;
            }

            Vector2 targetScreenPos = cam.WorldToScreen(lockedTarget.WorldPosition);
            Mouse.SetPosition((int)targetScreenPos.X, (int)targetScreenPos.Y);
        }

        public static float CalculateTurretTargetRotation()
        {
            if (ActiveTurret == null || lockedTarget == null) return 0f;

            Vector2 turretPos = GetTurretWorldPosition();
            Vector2 targetPos = lockedTarget.WorldPosition;
            Vector2 diff = targetPos - turretPos;
            diff.Y = -diff.Y;

            return MathUtils.VectorToAngle(diff);
        }

        private static void ClearLock()
        {
            lockedTarget = null;
            lockProgress = 0f;
        }


        public static void DrawAC6HUD(SpriteBatch spriteBatch, Vector2 crosshairPos, Character character)
        {
            if (!LockModeEnabled) return;

            var cam = Screen.Selected?.Cam;
            if (cam == null) return;

            ammoUpdateTimer += (float)Timing.Step;
            if (ammoUpdateTimer >= AmmoUpdateInterval)
            {
                ammoUpdateTimer = 0f;
                UpdateDualWeaponAmmo(character);
            }

            Vector2 screenCenter = new Vector2(cam.Resolution.X * 0.5f, cam.Resolution.Y * 0.5f);

            if (MultiTargetMode)
            {
                DrawMultiTargetHUD(spriteBatch, cam, character, screenCenter);
                return;
            }

            if (lockedTarget != null && lockProgress >= 1f && !lockedTarget.Removed && !lockedTarget.IsDead)
            {
                var targetScreenPos = cam.WorldToScreen(lockedTarget.WorldPosition);
                float distance = Vector2.Distance(character.WorldPosition, lockedTarget.WorldPosition) / PixelsPerMeter;
                DrawLockedHUD(spriteBatch, targetScreenPos, cachedLeftAmmo, cachedRightAmmo, distance);
            }
            else
            {
                DrawUnlockedHUD(spriteBatch, screenCenter, cachedLeftAmmo, cachedRightAmmo);
            }
        }

        private static void DrawMultiTargetHUD(SpriteBatch spriteBatch, Camera cam, Character character, Vector2 screenCenter)
        {
            DrawUnlockedHUD(spriteBatch, screenCenter, cachedLeftAmmo, cachedRightAmmo);

            Vector2 sourcePos = IsTurretMode ? GetTurretWorldPosition() : character.WorldPosition;

            for (int i = 0; i < sortedEnemiesList.Count; i++)
            {
                var enemy = sortedEnemiesList[i];
                if (enemy == null || enemy.Removed || enemy.IsDead) continue;

                var targetScreenPos = cam.WorldToScreen(enemy.WorldPosition);
                float distance = Vector2.Distance(sourcePos, enemy.WorldPosition) / PixelsPerMeter;

                DrawMultiTargetFrame(spriteBatch, targetScreenPos, i + 1, distance);
            }
        }

        private static void DrawMultiTargetFrame(SpriteBatch spriteBatch, Vector2 c, int index, float distance)
        {
            DrawCircle(spriteBatch, c, LockMiddleR, LockedFrameColor, 1.5f, 36);

            float markerSpan = MathF.PI * 0.11f;
            DrawArc(spriteBatch, c, LockMarkerR, -MathF.PI * 0.5f - markerSpan, -MathF.PI * 0.5f + markerSpan, LockedFrameColor, 3f, 6);
            DrawArc(spriteBatch, c, LockMarkerR, -markerSpan, markerSpan, LockedFrameColor, 3f, 6);
            DrawArc(spriteBatch, c, LockMarkerR, MathF.PI * 0.5f - markerSpan, MathF.PI * 0.5f + markerSpan, LockedFrameColor, 3f, 6);
            DrawArc(spriteBatch, c, LockMarkerR, MathF.PI - markerSpan, MathF.PI + markerSpan, LockedFrameColor, 3f, 6);

            float arcRad = MathHelper.ToRadians(CornerArcSpan * 0.5f);
            float cornerR = LockMiddleR + 40f;
            DrawCornerArcWithCaps(spriteBatch, c, cornerR, -MathF.PI * 0.75f - arcRad, -MathF.PI * 0.75f + arcRad, CornerArcColor, 2f, 8);
            DrawCornerArcWithCaps(spriteBatch, c, cornerR, -MathF.PI * 0.25f - arcRad, -MathF.PI * 0.25f + arcRad, CornerArcColor, 2f, 8);
            DrawCornerArcWithCaps(spriteBatch, c, cornerR, MathF.PI * 0.25f - arcRad, MathF.PI * 0.25f + arcRad, CornerArcColor, 2f, 8);
            DrawCornerArcWithCaps(spriteBatch, c, cornerR, MathF.PI * 0.75f - arcRad, MathF.PI * 0.75f + arcRad, CornerArcColor, 2f, 8);

            string indexText = index.ToString();
            var font = GUIStyle.LargeFont;
            Vector2 textSize = font.MeasureString(indexText);
            Vector2 textPos = new Vector2(c.X - textSize.X * 0.5f, c.Y - textSize.Y * 0.5f);
            GUI.DrawString(spriteBatch, textPos, indexText, LockMarkerColor, font: font);

            string distText = $"[ {distance:0}M ]";
            var smallFont = GUIStyle.SmallFont;
            Vector2 distSize = smallFont.MeasureString(distText);
            Vector2 distPos = new Vector2(c.X - distSize.X * 0.5f, c.Y + LockMiddleR + 15f);
            GUI.DrawString(spriteBatch, distPos, distText, DistanceColor, font: smallFont);
        }

        public static void DrawTurretHUD(SpriteBatch spriteBatch, Turret turret, Character character)
        {
            if (!LockModeEnabled) return;

            var cam = Screen.Selected?.Cam;
            if (cam == null) return;

            ammoUpdateTimer += (float)Timing.Step;
            if (ammoUpdateTimer >= AmmoUpdateInterval)
            {
                ammoUpdateTimer = 0f;
                UpdateTurretAmmo(turret);
            }

            Vector2 screenCenter = new Vector2(cam.Resolution.X * 0.5f, cam.Resolution.Y * 0.5f);
            Vector2 sourcePos = GetTurretWorldPosition();

            if (MultiTargetMode)
            {
                DrawMultiTargetHUD(spriteBatch, cam, character, screenCenter);
                return;
            }

            if (lockedTarget != null && lockProgress >= 1f && !lockedTarget.Removed && !lockedTarget.IsDead)
            {
                var targetScreenPos = cam.WorldToScreen(lockedTarget.WorldPosition);
                float distance = Vector2.Distance(sourcePos, lockedTarget.WorldPosition) / PixelsPerMeter;
                DrawLockedHUD(spriteBatch, targetScreenPos, cachedLeftAmmo, cachedRightAmmo, distance);
            }
            else
            {
                DrawUnlockedHUD(spriteBatch, screenCenter, cachedLeftAmmo, cachedRightAmmo);
            }
        }

        private static void UpdateTurretAmmo(Turret turret)
        {
            cachedLeftAmmo = 1f;
            cachedRightAmmo = 0f;

            if (turret?.Item == null) return;

            var linkedTo = turret.Item.linkedTo;
            for (int i = 0; i < linkedTo.Count; i++)
            {
                var linked = linkedTo[i];
                if (linked is not Item linkedItem) continue;
                var container = linkedItem.GetComponent<ItemContainer>();
                if (container != null)
                {
                    cachedRightAmmo = container.GetContainedIndicatorState();
                    break;
                }
            }
        }

        private static void UpdateDualWeaponAmmo(Character character)
        {
            cachedLeftAmmo = 1f;
            cachedRightAmmo = 0f;

            int weaponCount = 0;
            RangedWeapon firstWeapon = null;
            var heldItems = character.HeldItems;

            for (int i = 0; i < heldItems.Count(); i++)
            {
                var item = heldItems.ElementAt(i);
                var rw = item.GetComponent<RangedWeapon>();
                if (rw != null)
                {
                    weaponCount++;
                    if (firstWeapon == null) firstWeapon = rw;
                }
            }

            if (weaponCount == 0) return;

            if (weaponCount == 1 && firstWeapon != null)
            {
                var container = firstWeapon.Item.GetComponent<ItemContainer>();
                cachedRightAmmo = container?.GetContainedIndicatorState() ?? 0f;
            }
            else
            {
                var inventory = character.Inventory;
                if (inventory != null)
                {
                    var rightHand = inventory.GetItemInLimbSlot(InvSlotType.RightHand);
                    var leftHand = inventory.GetItemInLimbSlot(InvSlotType.LeftHand);

                    if (rightHand != null)
                    {
                        var container = rightHand.GetComponent<ItemContainer>();
                        cachedRightAmmo = container?.GetContainedIndicatorState() ?? 0f;
                    }
                    if (leftHand != null)
                    {
                        var container = leftHand.GetComponent<ItemContainer>();
                        cachedLeftAmmo = container?.GetContainedIndicatorState() ?? 0f;
                    }
                }
            }
        }

        private static void DrawUnlockedHUD(SpriteBatch spriteBatch, Vector2 c, float leftAmmo, float rightAmmo)
        {
            DrawCircle(spriteBatch, c, OuterR, CircleColor, 1.5f, 36);
            DrawCircle(spriteBatch, c, InnerR, CircleColor, 1.5f, 36);

            float a1 = -MathF.PI * 0.5f, a2 = MathF.PI / 6f, a3 = MathF.PI * 5f / 6f;
            DrawTick(spriteBatch, c, a1, InnerR - 2f, OuterR + 2f);
            DrawTick(spriteBatch, c, a2, InnerR - 2f, OuterR + 2f);
            DrawTick(spriteBatch, c, a3, InnerR - 2f, OuterR + 2f);

            ShapeExtensions.DrawLine(spriteBatch, new Vector2(c.X - CrossLen, c.Y), new Vector2(c.X - CrossGap, c.Y), CrosshairColor, 2.5f);
            ShapeExtensions.DrawLine(spriteBatch, new Vector2(c.X + CrossGap, c.Y), new Vector2(c.X + CrossLen, c.Y), CrosshairColor, 2.5f);
            ShapeExtensions.DrawLine(spriteBatch, new Vector2(c.X, c.Y - CrossLen), new Vector2(c.X, c.Y - CrossGap), CrosshairColor, 2.5f);
            ShapeExtensions.DrawLine(spriteBatch, new Vector2(c.X, c.Y + CrossGap), new Vector2(c.X, c.Y + CrossLen), CrosshairColor, 2.5f);

            float arcRad = MathHelper.ToRadians(CornerArcSpan * 0.5f);
            DrawCornerArcWithCaps(spriteBatch, c, CornerArcR, -MathF.PI * 0.75f - arcRad, -MathF.PI * 0.75f + arcRad, CornerArcColor, 2f, 8);
            DrawCornerArcWithCaps(spriteBatch, c, CornerArcR, -MathF.PI * 0.25f - arcRad, -MathF.PI * 0.25f + arcRad, CornerArcColor, 2f, 8);
            DrawCornerArcWithCaps(spriteBatch, c, CornerArcR, MathF.PI * 0.25f - arcRad, MathF.PI * 0.25f + arcRad, CornerArcColor, 2f, 8);
            DrawCornerArcWithCaps(spriteBatch, c, CornerArcR, MathF.PI * 0.75f - arcRad, MathF.PI * 0.75f + arcRad, CornerArcColor, 2f, 8);

            DrawAmmoArcs(spriteBatch, c, leftAmmo, rightAmmo, false);
        }

        private static void DrawTick(SpriteBatch spriteBatch, Vector2 c, float angle, float r1, float r2)
        {
            Vector2 dir = new Vector2(MathF.Cos(angle), MathF.Sin(angle));
            ShapeExtensions.DrawLine(spriteBatch, c + dir * r1, c + dir * r2, TickColor, 2f);
        }

        private static void DrawCornerArcWithCaps(SpriteBatch spriteBatch, Vector2 c, float r, float startA, float endA, Color color, float thickness, int seg)
        {
            DrawArc(spriteBatch, c, r, startA, endA, color, thickness, seg);

            Vector2 startDir = new Vector2(MathF.Cos(startA), MathF.Sin(startA));
            Vector2 endDir = new Vector2(MathF.Cos(endA), MathF.Sin(endA));
            Vector2 startPos = c + startDir * r;
            Vector2 endPos = c + endDir * r;

            Vector2 startPerp = new Vector2(-startDir.Y, startDir.X);
            Vector2 endPerp = new Vector2(endDir.Y, -endDir.X);

            ShapeExtensions.DrawLine(spriteBatch, startPos - startPerp * CornerCapLen, startPos + startPerp * CornerCapLen, color, thickness);
            ShapeExtensions.DrawLine(spriteBatch, endPos - endPerp * CornerCapLen, endPos + endPerp * CornerCapLen, color, thickness);
        }

        private static void DrawLockedHUD(SpriteBatch spriteBatch, Vector2 c, float leftAmmo, float rightAmmo, float distance)
        {
            DrawCircle(spriteBatch, c, LockMiddleR, LockedFrameColor, 1.5f, 36);

            float markerSpan = MathF.PI * 0.11f;
            DrawArc(spriteBatch, c, LockMarkerR, -MathF.PI * 0.5f - markerSpan, -MathF.PI * 0.5f + markerSpan, LockMarkerColor, 3f, 6);
            DrawArc(spriteBatch, c, LockMarkerR, -markerSpan, markerSpan, LockMarkerColor, 3f, 6);
            DrawArc(spriteBatch, c, LockMarkerR, MathF.PI * 0.5f - markerSpan, MathF.PI * 0.5f + markerSpan, LockMarkerColor, 3f, 6);
            DrawArc(spriteBatch, c, LockMarkerR, MathF.PI - markerSpan, MathF.PI + markerSpan, LockMarkerColor, 3f, 6);

            DrawAmmoArcs(spriteBatch, c, leftAmmo, rightAmmo, true);

            string distText = $"[ {distance:0}M ]";
            var font = GUIStyle.SmallFont;
            Vector2 textSize = font.MeasureString(distText);
            Vector2 textPos = new Vector2(c.X - textSize.X * 0.5f, c.Y + LockMiddleR + 15f);
            GUI.DrawString(spriteBatch, textPos, distText, DistanceColor, font: font);
        }


        private static void DrawAmmoArcs(SpriteBatch spriteBatch, Vector2 c, float leftAmmo, float rightAmmo, bool locked)
        {
            float r = locked ? LockMiddleR : AmmoArcR;
            float leftStart = MathF.PI * 0.55f;
            float leftEnd = MathF.PI * 0.95f;
            float rightStart = MathF.PI * 0.05f;
            float rightEnd = MathF.PI * 0.45f;

            DrawArc(spriteBatch, c, r, leftStart, leftEnd, AmmoArcBg, AmmoArcW, 8);
            DrawArc(spriteBatch, c, r, rightStart, rightEnd, AmmoArcBg, AmmoArcW, 8);

            if (leftAmmo > 0.01f)
            {
                float fillEnd = leftStart + (leftEnd - leftStart) * leftAmmo;
                DrawArc(spriteBatch, c, r, leftStart, fillEnd, AmmoArcFill, AmmoArcW, 8);
            }
            if (rightAmmo > 0.01f)
            {
                float fillStart = rightEnd - (rightEnd - rightStart) * rightAmmo;
                DrawArc(spriteBatch, c, r, fillStart, rightEnd, AmmoArcFill, AmmoArcW, 8);
            }
        }

        private static void DrawCircle(SpriteBatch spriteBatch, Vector2 c, float r, Color color, float thickness, int seg)
        {
            float step = MathF.PI * 2f / seg;
            float cos = MathF.Cos(step);
            float sin = MathF.Sin(step);
            float x = r, y = 0f;

            for (int i = 0; i < seg; i++)
            {
                float nx = x * cos - y * sin;
                float ny = x * sin + y * cos;
                ShapeExtensions.DrawLine(spriteBatch, new Vector2(c.X + x, c.Y + y), new Vector2(c.X + nx, c.Y + ny), color, thickness);
                x = nx; y = ny;
            }
        }

        private static void DrawArc(SpriteBatch spriteBatch, Vector2 c, float r, float startA, float endA, Color color, float thickness, int seg)
        {
            float step = (endA - startA) / seg;
            float prevX = c.X + MathF.Cos(startA) * r;
            float prevY = c.Y + MathF.Sin(startA) * r;

            for (int i = 1; i <= seg; i++)
            {
                float a = startA + i * step;
                float currX = c.X + MathF.Cos(a) * r;
                float currY = c.Y + MathF.Sin(a) * r;
                ShapeExtensions.DrawLine(spriteBatch, new Vector2(prevX, prevY), new Vector2(currX, currY), color, thickness);
                prevX = currX; prevY = currY;
            }
        }
    }

    [HarmonyPatch(typeof(Controller), nameof(Controller.SecondaryUse))]
    public static class Controller_SecondaryUse_Patch
    {
        public static void Postfix(Controller __instance, float deltaTime, Character character)
        {
            if (!AC6TargetingHUDAuto.LockModeEnabled) return;
            if (!AC6TargetingHUDAuto.IsTurretMode) return;
            if (!AC6TargetingHUDAuto.IsLocked) return;
            if (AC6TargetingHUDAuto.ActiveController != __instance) return;

            var cam = Screen.Selected?.Cam;
            if (cam == null) return;

            var target = AC6TargetingHUDAuto.LockedTarget;
            if (target == null || target.Removed || target.IsDead) return;

            Vector2 targetScreenPos = cam.WorldToScreen(target.WorldPosition);
            Mouse.SetPosition((int)targetScreenPos.X, (int)targetScreenPos.Y);
        }
    }

    [HarmonyPatch(typeof(Turret), nameof(Turret.DrawHUD))]
    public static class Turret_DrawHUD_Patch
    {
        public static void Postfix(Turret __instance, SpriteBatch spriteBatch, Character character)
        {
            if (character != Character.Controlled) return;
            if (!AC6TargetingHUDAuto.LockModeEnabled) return;
            if (!AC6TargetingHUDAuto.IsTurretMode) return;
            if (AC6TargetingHUDAuto.ActiveTurret != __instance) return;

            AC6TargetingHUDAuto.DrawTurretHUD(spriteBatch, __instance, character);
        }
    }
}
