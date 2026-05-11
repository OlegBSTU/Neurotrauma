using System;
using System.Reflection;
using Barotrauma;
using HarmonyLib;
using Microsoft.Xna.Framework;

using System.Collections.Generic;
using System.Collections.Immutable;
using System.Linq;
using Barotrauma.Networking;
using Microsoft.Xna.Framework;

using Barotrauma.Lights;

      // patching this method https://github.com/evilfactory/LuaCsForBarotrauma/blob/ad837423a8d71666dc0a5621713e2ab1fe7e2802/Barotrauma/BarotraumaClient/ClientSource/Items/Components/Signal/CircuitBox.cs#L266
namespace FPGAPatch
{
  class FPGAPatchMod : IAssemblyPlugin
  {
    public Harmony harmony;
    public void Initialize()
    {
      harmony = new Harmony("onlyfullfpga.mod");

      harmony.Patch(
        original: typeof(Barotrauma.Items.Components.CircuitBox).GetMethod("AddComponent"),
        prefix: new HarmonyMethod(typeof(FPGAPatchMod).GetMethod("AddComponent"))
      );
    }
    public void OnLoadCompleted() { }
    public void PreInitPatching() { }

    public void Dispose()
    {
      harmony.UnpatchSelf();
      harmony = null;
    }

    public static bool AddComponent(ItemPrefab prefab, Vector2 pos, Barotrauma.Items.Components.CircuitBox __instance)
        {
            Barotrauma.Items.Components.CircuitBox _ = __instance;
            {
                if (_.IsLocked()) { return false; }
                if (GameMain.NetworkMember is null)
                {
                    ItemPrefab resource;

                    if (_.IsFull) { return false; }

                    if (Barotrauma.Items.Components.CircuitBox.IsInGame())
                    {
                        if (!Barotrauma.Items.Components.CircuitBox.GetApplicableResourcePlayerHas(prefab, Character.Controlled).TryUnwrap(out var r)) { return false; }
                        if (r.Condition < 100.0f) // patch for full condition FPGA
                        {
                            return false;
                        }
                        resource = r.Prefab;
                        Barotrauma.Items.Components.CircuitBox.RemoveItem(r);
                    }
                    else
                    {
                        resource = ItemPrefab.Prefabs[Tags.FPGACircuit];
                    }
                    _.AddComponentInternal(ICircuitBoxIdentifiable.FindFreeID(_.Components), prefab, resource, pos, Character.Controlled, onItemSpawned: null);
                    return false;
                }

                _.CreateClientEvent(new CircuitBoxAddComponentEvent(prefab.UintIdentifier, pos));
                return false;
            }
        }
    }
}
