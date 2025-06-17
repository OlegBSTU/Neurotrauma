TagsToAdd = { "id_medic", "id_medical", "id_medicaldoctor", "med" }

function upgradeIDCard(instance, ptable)
	item = instance.item
	if item.HasTag("jobid:surgeon") then
		updated = false

		-- Has to be added before to preserve the job identification
		if not item.HasTag("jobid:medicaldoctor") then
			item.Tags = "jobid:medicaldoctor," .. item.Tags
			updated = true
		end

		for i in TagsToAdd do
			if not item.HasTag(i) then
				item.AddTag(i)
				updated = true
			end
		end

		if updated and SERVER then
			Networking.CreateEntityEvent(
				item,
				Item.ChangePropertyEventData(item.SerializableProperties[Identifier("Tags")], item)
			)
		end
	end
end

-- jobid:surgeon
--id_medicaldoctor or jobid:medicaldoctor or id_medic
Hook.Patch("Barotrauma.Items.Components.IdCard", "OnItemLoaded", upgradeIDCard, Hook.HookMethodType.After)

Hook.Patch("Barotrauma.Items.Components.IdCard", "Initialize", upgradeIDCard, Hook.HookMethodType.After)
