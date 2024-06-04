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

namespace CharacterHealthMod
{
  class CharacterHealthMod : IAssemblyPlugin
  {
    public Harmony harmony;
	public Item armor;
	
    public void Initialize()
    {
      harmony = new Harmony("CharacterHealth");

	harmony.Patch(
		original: typeof(CharacterHealth).GetMethod("Update"),
		prefix: new HarmonyMethod(typeof(CharacterHealthMod).GetMethod("Update"))
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
			if (_.Character.IsHuman && !_.Character.AnimController.IsUsingItem && _.Character.AnimController.CurrentAnimationParams == _.Character.AnimController.SwimFastParams)
			{
				_.ApplyAffliction(_.Character.AnimController.MainLimb, AfflictionPrefab.Prefabs["nthm_fatigue"].Instantiate(10f * deltaTime));
			}
			else if (_.Character.IsHuman && _.Character.AnimController.CurrentAnimationParams == _.Character.AnimController.SwimSlowParams)
			{
				_.ApplyAffliction(_.Character.AnimController.MainLimb, AfflictionPrefab.Prefabs["nthm_fatigue"].Instantiate(-10f * deltaTime));
			}
			else if (_.Character.IsHuman && !_.Character.IsDead)
			{
				_.ApplyAffliction(_.Character.AnimController.MainLimb, AfflictionPrefab.Prefabs["nthm_fatigue"].Instantiate(-20f * deltaTime));
				Vector2 velocity = _.Character.AnimController.MainLimb.body.LinearVelocity
				if (Math.Pow(Math.Pow(velocity.X,2) + (Math.Pow(velocity.Y,2)),0.5) <= 0.1)
				{
				_.ApplyAffliction(_.Character.AnimController.MainLimb, AfflictionPrefab.Prefabs["nthm_motionless"].Instantiate(2f * deltaTime));
				}
			}
			if (_.Character.IsHuman && !_.Character.IsDead)
			{
				_.Character.PressureTimer = 0.0f
				if (_.Character.PressureProtection < _.Character.WorldPosition.Y && _.Character.InPressure)
				{
					_.ApplyAffliction(_.Character.AnimController.MainLimb, AfflictionPrefab.Prefabs["nthm_diversbarotrauma"].Instantiate(4f * deltaTime));
				}
				else
				{
					_.ApplyAffliction(_.Character.AnimController.MainLimb, AfflictionPrefab.Prefabs["nthm_diversbarotrauma"].Instantiate(-2f * deltaTime));
				}
			}
		
		}

	
  }
}
