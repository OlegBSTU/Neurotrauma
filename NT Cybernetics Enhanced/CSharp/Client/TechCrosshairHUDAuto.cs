using Barotrauma;
using Barotrauma.Items.Components;
using HarmonyLib;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using System;
using System.Collections.Immutable;
using System.Linq;

namespace NTCeHUDAutoMod.TechCrosshairHUDAuto
{
    public class TechCrosshairHUDAuto : IAssemblyPlugin
    {
        public static float HitHintTimer { get; set; }
        public static int HitHintSize { get; set; } = 12;
        public static int CrosshairDistance { get; set; } = 12;
        public static float IndicatorRadiusStart { get; set; } = 45.0f;
        public static float IndicatorThickness { get; set; } = 4.0f;
        public static float IndicatorSectionRad { get; set; } = 0.25f * 2.0f * MathF.PI;
        public static float IndicatorRotationAngle { get; set; } = 0.125f * 2.0f * MathF.PI;

        public static Color TechCyan { get; } = new Color(0, 200, 255, 255);
        public static Color TechRed { get; } = new Color(200, 30, 60, 255);
        public static Color TechGold { get; } = new Color(255, 215, 120, 255);
        public static Color TechGoldDark { get; } = new Color(180, 150, 80, 255);
        public static Color TechGray { get; } = new Color(80, 90, 100, 180);

        private static readonly Identifier CyberEyeAffliction = new Identifier("vi_cyber");
        public static bool CyberEyeEnabled { get; private set; } = false;
        private static float cyberEyeCheckTimer = 0f;
        private const float CyberEyeCheckInterval = 0.5f;

        private static bool vKeyPressedLastFrame = false;
        public Harmony harmonyInstance;

        public void Initialize()
        {
            harmonyInstance = new Harmony("NTCeHUDAutoMod.TechCrosshairHUDAuto");
        }

        public void Dispose()
        {
            harmonyInstance?.UnpatchSelf();
        }

        public void OnLoadCompleted()
        {
            harmonyInstance?.PatchAll();
            GameMain.LuaCs.Hook.Add("think", "UpdateTechCrosshairHUDAuto", UpdateHUD);
        }

        public void PreInitPatching() { }

        public static bool ShouldEnableHUD()
        {
            var character = Character.Controlled;
            if (character == null || character.IsDead) return false;

            if (CyberEyeEnabled) return true;

            return false;
        }

        private static void UpdateCyberEyeStatus()
        {
            var character = Character.Controlled;
            if (character == null || character.IsDead || character.CharacterHealth == null)
            {
                CyberEyeEnabled = false;
                return;
            }

            var affliction = character.CharacterHealth.GetAffliction(CyberEyeAffliction);
            CyberEyeEnabled = affliction != null && affliction.Strength >= 0.1f;
        }

        public static object[]? UpdateHUD(object[]? args)
        {
            HitHintTimer -= (float)Timing.Step;
            HitHintTimer = Math.Max(HitHintTimer, 0);

            cyberEyeCheckTimer += (float)Timing.Step;
            if (cyberEyeCheckTimer >= CyberEyeCheckInterval)
            {
                cyberEyeCheckTimer = 0f;
                UpdateCyberEyeStatus();
            }

            bool vKeyDown = GUI.KeyboardDispatcher.Subscriber == null && PlayerInput.KeyDown(Microsoft.Xna.Framework.Input.Keys.V);
            if (vKeyDown && !vKeyPressedLastFrame)
            {
                AC6TargetingHUDAuto.AC6TargetingHUDAuto.LockModeEnabled = !AC6TargetingHUDAuto.AC6TargetingHUDAuto.LockModeEnabled;
            }
            vKeyPressedLastFrame = vKeyDown;

            return null;
        }

        [HarmonyPatch(typeof(Character), nameof(Character.ApplyAttack))]
        public static class ApplyAttackPatch
        {
            public static void Postfix(Character __instance, Character attacker, AttackResult __result)
            {
                if (__instance == null || attacker == null) return;
                if (__result.Damage == 0 && __result.Afflictions == null) return;
                if (attacker == Character.Controlled)
                {
                    if (IsOutOfScreen(__instance.WorldPosition)) return;
                    HitHintTimer = 0.4f;
                }
            }

            private static bool IsOutOfScreen(Vector2 position)
            {
                if (Screen.Selected?.Cam == null) return true;
                var view = Screen.Selected.Cam.WorldView;
                return position.X < view.X || position.X > view.Right ||
                       position.Y > view.Y || position.Y < view.Y - view.Height;
            }
        }

        [HarmonyPatch(typeof(RangedWeapon), nameof(RangedWeapon.DrawHUD))]
        static class RangedWeapon_DrawHUD_Patch
        {
            static void Postfix(RangedWeapon __instance, SpriteBatch spriteBatch, Character character)
            {
                if (__instance == null || character != Character.Controlled) return;
                if (!character.IsKeyDown(InputType.Aim) || !character.CanAim) return;
                if (!character.HeldItems.Contains(__instance.Item)) return;
                if (!ShouldEnableHUD()) return;

                if (AC6TargetingHUDAuto.AC6TargetingHUDAuto.LockModeEnabled)
                {
                    AC6TargetingHUDAuto.AC6TargetingHUDAuto.DrawAC6HUD(spriteBatch, __instance.crosshairPos, character);
                }
                else
                {
                    DrawTechHUD(__instance, spriteBatch, character);
                }
            }
        }

        public static void DrawTechHUD(RangedWeapon rangedWeapon, SpriteBatch spriteBatch, Character character)
        {
            var position = rangedWeapon.crosshairPos;
            var itemContainer = rangedWeapon.Item.GetComponent<ItemContainer>();
            if (itemContainer == null) return;

            float containedState = itemContainer.GetContainedIndicatorState();
            Color indicatorColor = Color.Lerp(TechRed, TechCyan, containedState);

            DrawHitMarker(spriteBatch, position);
            DrawTechFrame(spriteBatch, position);
            DrawAmmoArc(spriteBatch, position, containedState, indicatorColor);
            DrawAmmoInfo(spriteBatch, position, containedState, indicatorColor, rangedWeapon.Item, itemContainer);
        }

        private static void DrawHitMarker(SpriteBatch spriteBatch, Vector2 position)
        {
            float alpha = HitHintTimer > 0 ? Math.Min(HitHintTimer * 3f, 1f) : 0f;
            Color hitColor = new Color(255, 255, 255, (int)(alpha * 255));
            int d = CrosshairDistance, s = HitHintSize;
            float thickness = 2f;

            ShapeExtensions.DrawLine(spriteBatch, new Vector2(position.X + d, position.Y + d), new Vector2(position.X + d + s, position.Y + d + s), hitColor, thickness);
            ShapeExtensions.DrawLine(spriteBatch, new Vector2(position.X - d, position.Y + d), new Vector2(position.X - d - s, position.Y + d + s), hitColor, thickness);
            ShapeExtensions.DrawLine(spriteBatch, new Vector2(position.X + d, position.Y - d), new Vector2(position.X + d + s, position.Y - d - s), hitColor, thickness);
            ShapeExtensions.DrawLine(spriteBatch, new Vector2(position.X - d, position.Y - d), new Vector2(position.X - d - s, position.Y - d - s), hitColor, thickness);
        }

        private static void DrawTechFrame(SpriteBatch spriteBatch, Vector2 position)
        {
            float r = IndicatorRadiusStart + IndicatorThickness + 8f;
            float segmentLength = 8f, gap = 6f;
            for (int i = 0; i < 4; i++)
            {
                float angle = i * MathF.PI / 2f + MathF.PI / 4f;
                Vector2 start = position + new Vector2(MathF.Cos(angle), MathF.Sin(angle)) * (r + gap);
                Vector2 end = position + new Vector2(MathF.Cos(angle), MathF.Sin(angle)) * (r + gap + segmentLength);
                ShapeExtensions.DrawLine(spriteBatch, start, end, TechGray, 1f);
            }
        }

        private static void DrawAmmoArc(SpriteBatch spriteBatch, Vector2 position, float containedState, Color indicatorColor)
        {
            TechGUIExtensionsAuto.DrawDonutSectionOutLine(spriteBatch, position,
                new Range<float>(IndicatorRadiusStart - 1f, IndicatorRadiusStart + IndicatorThickness + 1f),
                IndicatorSectionRad, TechGray, 0, IndicatorRotationAngle);

            float displayState = Math.Max(containedState, 0.01f);
            TechGUIExtensionsAuto.DrawDonutSection(spriteBatch, position,
                new Range<float>(IndicatorRadiusStart, IndicatorRadiusStart + IndicatorThickness),
                displayState * IndicatorSectionRad, indicatorColor, 0,
                IndicatorRotationAngle + IndicatorSectionRad, false);
        }

        private static void DrawAmmoInfo(SpriteBatch spriteBatch, Vector2 position, float containedState, Color indicatorColor, Item item, ItemContainer itemContainer)
        {
            float percent = containedState * 100f;
            var (ammoCount, isSpecial) = GetCurrentAmmoCount(item, itemContainer);

            Vector2 percentPos = new Vector2(position.X - IndicatorRadiusStart - 30f, position.Y + IndicatorRadiusStart + 5f);
            Vector2 ammoPos = new Vector2(position.X + IndicatorRadiusStart + 8f, position.Y + IndicatorRadiusStart + 5f);

            GUI.DrawString(spriteBatch, percentPos, $"{percent:0}%", indicatorColor, font: GUIStyle.SmallFont);
            if (isSpecial)
                GUI.DrawString(spriteBatch, ammoPos, "XXX", TechGoldDark, font: GUIStyle.SmallFont);
            else
                GUI.DrawString(spriteBatch, ammoPos, Math.Min(ammoCount, 999).ToString().PadLeft(3, '0'), TechGold, font: GUIStyle.SmallFont);
        }

        private static (int count, bool isSpecial) GetCurrentAmmoCount(Item item, ItemContainer itemContainer)
        {
            if (item.OwnInventory == null) return (0, false);
            int capacity = itemContainer.MainContainerCapacity;
            int totalCount = 0;
            bool hasNestedMag = false, isSpecialAmmo = false;

            for (int i = 0; i < capacity; i++)
            {
                var items = item.OwnInventory.GetItemsAt(i);
                if (items == null) continue;
                foreach (var containedItem in items)
                {
                    if (containedItem == null) continue;
                    var nestedContainer = containedItem.GetComponent<ItemContainer>();
                    if (nestedContainer != null && containedItem.OwnInventory != null)
                    {
                        hasNestedMag = true;
                        int nestedCount = 0;
                        for (int j = 0; j < nestedContainer.MainContainerCapacity; j++)
                        {
                            var nestedItems = containedItem.OwnInventory.GetItemsAt(j);
                            if (nestedItems != null) foreach (var _ in nestedItems) nestedCount++;
                        }
                        if (nestedCount <= 1) isSpecialAmmo = true;
                        else totalCount += nestedCount;
                    }
                    else totalCount++;
                }
            }
            return (hasNestedMag && isSpecialAmmo && totalCount == 0) ? (0, true) : (totalCount, false);
        }
    }

    public static class TechGUIExtensionsAuto
    {
        public const int DonutSegments = 30;
        public static readonly VertexPositionColorTexture[] donutVerts = new VertexPositionColorTexture[DonutSegments * 4];
        public static readonly ImmutableArray<Vector2> canonicalCircle = Enumerable.Range(0, DonutSegments)
            .Select(i => i * (2.0f * MathF.PI / DonutSegments))
            .Select(angle => new Vector2(MathF.Cos(angle), MathF.Sin(angle)))
            .ToImmutableArray();

        private static Vector2 GetDirection(int index, float sectionProportion, int maxDirectionIndex)
        {
            int directionIndex = (index % 4) switch { 0 => (index / 4), 1 => (index / 4) + 1, 2 => (index / 4), 3 => (index / 4) + 1, _ => 0 };
            Vector2 direction = canonicalCircle[directionIndex % DonutSegments];
            if (maxDirectionIndex > 0 && directionIndex >= maxDirectionIndex)
            {
                float maxSectionProportion = (float)maxDirectionIndex / DonutSegments;
                direction = Vector2.Lerp(canonicalCircle[maxDirectionIndex - 1], canonicalCircle[maxDirectionIndex % DonutSegments], 1.0f - (maxSectionProportion - sectionProportion) * DonutSegments);
            }
            return new Vector2(direction.Y, -direction.X);
        }

        private static float GetRadius(int index, ref Range<float> radii) => (index % 4) switch { 0 => radii.End, 1 => radii.End, 2 => radii.Start, 3 => radii.Start, _ => radii.Start };

        private static Vector2 RotatePoint(Vector2 center, Vector2 vertexPosition, float rotationAngle)
        {
            float cos = MathF.Cos(rotationAngle), sin = MathF.Sin(rotationAngle);
            float ox = vertexPosition.X - center.X, oy = vertexPosition.Y - center.Y;
            return new Vector2(cos * ox - sin * oy + center.X, sin * ox + cos * oy + center.Y);
        }

        public static void DrawDonutSection(SpriteBatch sb, Vector2 center, Range<float> radii, float sectionRad, Color clr, float depth = 0f, float rotationAngle = 0f, bool clockwise = true)
        {
            if (!clockwise) rotationAngle -= sectionRad;
            float sectionProportion = sectionRad / (MathF.PI * 2f);
            int maxDirectionIndex = Math.Min(DonutSegments, (int)MathF.Ceiling(sectionProportion * DonutSegments));
            for (int i = 0; i < maxDirectionIndex * 4; i++)
            {
                Vector2 direction = GetDirection(i, sectionProportion, maxDirectionIndex);
                Vector2 pos = new(center.X + direction.X * GetRadius(i, ref radii), center.Y + direction.Y * GetRadius(i, ref radii));
                Vector2 rotated = RotatePoint(center, pos, rotationAngle);
                donutVerts[i].Color = clr;
                donutVerts[i].Position = new Vector3(rotated, depth);
            }
            sb.Draw(GUI.WhiteTexture, donutVerts, depth, count: maxDirectionIndex);
        }

        public static void DrawDonutSectionOutLine(SpriteBatch sb, Vector2 center, Range<float> radii, float sectionRad, Color outlineclr, float depth = 0f, float rotationAngle = 0f)
        {
            float w = 1f;
            DrawDonutSection(sb, center, new Range<float>(radii.Start - w, radii.Start), sectionRad, outlineclr, depth, rotationAngle);
            DrawDonutSection(sb, center, new Range<float>(radii.End, radii.End + w), sectionRad, outlineclr, depth, rotationAngle);
            Vector2 s1 = new(center.X + (radii.Start - w) * MathF.Sin(rotationAngle), center.Y + (radii.Start - w) * MathF.Cos(rotationAngle));
            Vector2 e1 = new(center.X + (radii.End + w) * MathF.Sin(rotationAngle), center.Y + (radii.End + w) * MathF.Cos(rotationAngle));
            GUI.DrawLine(sb, s1, e1, outlineclr, depth);
            Vector2 s2 = new(center.X + (radii.Start - w) * MathF.Sin(rotationAngle + sectionRad), center.Y + (radii.Start - w) * MathF.Cos(rotationAngle + sectionRad));
            Vector2 e2 = new(center.X + (radii.End + w) * MathF.Sin(rotationAngle + sectionRad), center.Y + (radii.End + w) * MathF.Cos(rotationAngle + sectionRad));
            GUI.DrawLine(sb, s2, e2, outlineclr, depth);
        }
    }
}
