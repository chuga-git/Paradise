
/// Nothing will be filtered.
#define FILTER_NOTHING -1
/// Plasma, and Oxygen Agent B.
#define FILTER_TOXINS 0
/// Oxygen only.
#define FILTER_OXYGEN 1
/// Nitrogen only.
#define FILTER_NITROGEN 2
/// Carbon dioxide only.
#define FILTER_CO2 3
/// Nitrous oxide only.
#define FILTER_N2O 4

/obj/machinery/atmospherics/trinary/filter
	name = "gas filter"
	icon = 'icons/atmos/filter.dmi'
	icon_state = "map"
	can_unwrench = TRUE

	target_pressure = ONE_ATMOSPHERE
	/// The type of gas we want to filter. Valid values that go here are from the `FILTER` defines at the top of the file.
	var/filter_type = FILTER_TOXINS
	/// A list of available filter options. Used with `ui_data`.
	var/list/filter_list = list(
		"Nothing" = FILTER_NOTHING,
		"Plasma" = FILTER_TOXINS,
		"O2" = FILTER_OXYGEN,
		"N2" = FILTER_NITROGEN,
		"CO2" = FILTER_CO2,
		"N2O" = FILTER_N2O
	)

// So we can CtrlClick without triggering the anchored message.
/obj/machinery/atmospherics/trinary/filter/can_be_pulled(user, grab_state, force, show_message)
	return FALSE

/obj/machinery/atmospherics/trinary/filter/CtrlClick(mob/living/user)
	if(can_use_shortcut(user))
		toggle(user)
		investigate_log("was turned [on ? "on" : "off"] by [key_name(user)]", INVESTIGATE_ATMOS)
	return ..()

/obj/machinery/atmospherics/trinary/filter/AICtrlClick(mob/living/silicon/user)
	toggle(user)
	investigate_log("was turned [on ? "on" : "off"] by [key_name(user)]", INVESTIGATE_ATMOS)

/obj/machinery/atmospherics/trinary/filter/AltClick(mob/living/user)
	if(can_use_shortcut(user))
		set_max(user)
		investigate_log("was set to [target_pressure] kPa by [key_name(user)]", INVESTIGATE_ATMOS)

/obj/machinery/atmospherics/trinary/filter/AIAltClick(mob/living/silicon/user)
	set_max(user)
	investigate_log("was set to [target_pressure] kPa by [key_name(user)]", INVESTIGATE_ATMOS)

/obj/machinery/atmospherics/trinary/filter/flipped
	icon_state = "mmap"
	flipped = TRUE

/obj/machinery/atmospherics/trinary/filter/update_icon_state()
	if(flipped)
		icon_state = "m"
	else
		icon_state = ""

	if(!has_power())
		icon_state += "off"
	else if(node2 && node3 && node1)
		icon_state += on ? "on" : "off"
	else
		icon_state += "off"
		on = FALSE

/obj/machinery/atmospherics/trinary/filter/update_underlays()
	if(..())
		underlays.Cut()
		var/turf/T = get_turf(src)
		if(!istype(T))
			return

		add_underlay(T, node1, turn(dir, -180))

		if(flipped)
			add_underlay(T, node2, turn(dir, 90))
		else
			add_underlay(T, node2, turn(dir, -90))

		add_underlay(T, node3, dir)

/obj/machinery/atmospherics/trinary/filter/power_change()
	if(!..())
		return
	update_icon()

/obj/machinery/atmospherics/trinary/filter/process_atmos()
	if((stat & (NOPOWER|BROKEN)) || !on)
		return FALSE

	var/output_starting_pressure = air3.return_pressure()

	if(output_starting_pressure >= target_pressure || (filter_type != FILTER_NOTHING && air2.return_pressure() >= target_pressure))
		//No need to mix if target is already full!
		return TRUE

	//Calculate necessary moles to transfer using PV=nRT

	var/pressure_delta = target_pressure - output_starting_pressure
	var/transfer_moles

	if(air1.temperature() > 0)
		transfer_moles = pressure_delta * air3.volume / (air1.temperature() * R_IDEAL_GAS_EQUATION)

	//Actually transfer the gas

	if(transfer_moles > 0)
		var/datum/gas_mixture/removed = air1.remove(transfer_moles)

		if(!removed)
			return
		var/datum/gas_mixture/filtered_out = new
		filtered_out.set_temperature(removed.temperature())

		switch(filter_type)
			if(FILTER_TOXINS)
				filtered_out.set_toxins(removed.toxins())
				removed.set_toxins(0)

				filtered_out.set_agent_b(removed.agent_b())
				removed.set_agent_b(0)

			if(FILTER_OXYGEN)
				filtered_out.set_oxygen(removed.oxygen())
				removed.set_oxygen(0)

			if(FILTER_NITROGEN)
				filtered_out.set_nitrogen(removed.nitrogen())
				removed.set_nitrogen(0)

			if(FILTER_CO2)
				filtered_out.set_carbon_dioxide(removed.carbon_dioxide())
				removed.set_carbon_dioxide(0)

			if(FILTER_N2O)
				filtered_out.set_sleeping_agent(removed.sleeping_agent())
				removed.set_sleeping_agent(0)
			else
				filtered_out = null


		air2.merge(filtered_out)
		air3.merge(removed)

	if(!QDELETED(parent1))
		parent1.update = 1

	if(!QDELETED(parent2))
		parent2.update = 1

	if(!QDELETED(parent3))
		parent3.update = 1

	return TRUE

/obj/machinery/atmospherics/trinary/filter/attack_ghost(mob/user)
	ui_interact(user)

/obj/machinery/atmospherics/trinary/filter/attack_hand(mob/user)
	if(..())
		return

	if(!allowed(user))
		to_chat(user, "<span class='alert'>Access denied.</span>")
		return

	add_fingerprint(user)
	ui_interact(user)

/obj/machinery/atmospherics/trinary/filter/ui_state(mob/user)
	return GLOB.default_state

/obj/machinery/atmospherics/trinary/filter/ui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AtmosFilter", name)
		ui.open()

/obj/machinery/atmospherics/trinary/filter/ui_data(mob/user)
	var/list/data = list(
		"on" = on,
		"pressure" = round(target_pressure),
		"max_pressure" = round(MAX_OUTPUT_PRESSURE),
		"filter_type" = filter_type
	)
	data["filter_type_list"] = list()
	for(var/label in filter_list)
		data["filter_type_list"] += list(list("label" = label, "gas_type" = filter_list[label]))

	return data

/obj/machinery/atmospherics/trinary/filter/ui_act(action, list/params)
	if(..())
		return

	switch(action)
		if("power")
			toggle()
			investigate_log("was turned [on ? "on" : "off"] by [key_name(usr)]", INVESTIGATE_ATMOS)
			return TRUE

		if("set_filter")
			filter_type = text2num(params["filter"])
			investigate_log("was set to filter [filter_type] by [key_name(usr)]", INVESTIGATE_ATMOS)
			return TRUE

		if("max_pressure")
			target_pressure = MAX_OUTPUT_PRESSURE
			. = TRUE

		if("min_pressure")
			target_pressure = 0
			. = TRUE

		if("custom_pressure")
			target_pressure = clamp(text2num(params["pressure"]), 0, MAX_OUTPUT_PRESSURE)
			. = TRUE
	if(.)
		investigate_log("was set to [target_pressure] kPa by [key_name(usr)]", INVESTIGATE_ATMOS)

/obj/machinery/atmospherics/trinary/filter/item_interaction(mob/living/user, obj/item/used, list/modifiers)
	if(is_pen(used))
		rename_interactive(user, used)
		return ITEM_INTERACT_COMPLETE

	return ..()

#undef FILTER_NOTHING
#undef FILTER_TOXINS
#undef FILTER_OXYGEN
#undef FILTER_NITROGEN
#undef FILTER_CO2
#undef FILTER_N2O
