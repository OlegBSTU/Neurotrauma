using System;
using System.Reflection;
using Barotrauma;
using HarmonyLib;
using Microsoft.Xna.Framework;


using Barotrauma.Abilities;
using Barotrauma.Extensions;
using Barotrauma.Networking;


using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Xml.Linq;

// patching this method https://github.com/evilfactory/LuaCsForBarotrauma/blob/c518b696f61a139680d51c182573f7046adf8018/Barotrauma/BarotraumaShared/SharedSource/Characters/Health/CharacterHealth.cs#L843

namespace CharacterHealthMod
{
	class CharacterHealthMod : IAssemblyPlugin
	{
		public Harmony harmony;

		public void Initialize()
		{
			harmony = new Harmony("CharacterHealth");

			harmony.Patch(
				original: typeof(CharacterHealth).GetMethod("Update"),
				postfix: new HarmonyMethod(typeof(CharacterHealthMod).GetMethod("Update"))
			);
		}
		public void OnLoadCompleted() { }
		public void PreInitPatching() { }

		public void Dispose()
		{
			harmony.UnpatchAll();
			harmony = null;
		}

		public static void Update(CharacterHealth __instance, float deltaTime)
		{
			CharacterHealth _ = __instance;
			//DebugConsole.NewMessage("s");
			if (_.Character.IsPlayer && !_.Character.AnimController.IsUsingItem && _.Character.AnimController.CurrentAnimationParams == _.Character.AnimController.SwimFastParams)
			{
				_.ApplyAffliction(_.Character.AnimController.MainLimb, AfflictionPrefab.Prefabs["swimfatigue"].Instantiate(11f * deltaTime));
			}
			else if (_.Character.IsPlayer && !_.Character.IsDead)
			{
				_.ApplyAffliction(_.Character.AnimController.MainLimb, AfflictionPrefab.Prefabs["hypercapnia"].Instantiate(-1f * deltaTime));
				Vector2 velocity = _.Character.AnimController.MainLimb.body.LinearVelocity;
				if (_.isUnconscious)
				{
					_.ApplyAffliction(_.Character.AnimController.MainLimb, AfflictionPrefab.Prefabs["hypercapnia"].Instantiate(-1f * deltaTime));
				}
				else if (Math.Pow(Math.Pow(velocity.X, 2) + (Math.Pow(velocity.Y, 2)), 0.5) <= 0.1)
				{
					_.ApplyAffliction(_.Character.AnimController.MainLimb, AfflictionPrefab.Prefabs["hypercapnia"].Instantiate(-1f * deltaTime));
				}
			}
			if (_.Character.IsHuman && !_.Character.IsDead)
			{
				// _.Character.PressureTimer = 0.0f
				if (!_.Character.IsProtectedFromPressure && _.Character.InPressure)
				{
					_.Character.PressureTimer = 0.0f;
					_.ApplyAffliction(_.Character.AnimController.MainLimb, AfflictionPrefab.Prefabs["diversbarotrauma"].Instantiate(6.0f * deltaTime));
				}
			}
		}
	}
}
