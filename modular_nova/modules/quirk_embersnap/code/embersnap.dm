/datum/quirk/embersnap
	name = "Embersnap"
	desc = "With a snap, you are able to light a tiny flame in your hand!"
	gain_text = span_orange("Your hands feel flammable.")
	lose_text = span_notice("Your hands feel normal again.")
	medical_record_text = "Patient is able to light a tiny fire in their hands."
	value = 0
	icon = FA_ICON_FIRE_FLAME_CURVED
	/// Ref used to easily retrieve the action used when removing the quirk from silicons
	var/datum/weakref/ember_action_ref

/datum/quirk/embersnap/add(client/client_source)
		var/datum/action/cooldown/spell/conjure_item/embers/ember_action = new

		ember_action.Grant(quirk_holder)
		ember_action_ref = WEAKREF(ember_action)

/datum/quirk/embersnap/remove()
	var/datum/action/cooldown/spell/conjure_item/embers/ember_action = ember_action_ref?.resolve()
	if (!isnull(ember_action))
		QDEL_NULL(ember_action)
	ember_action_ref = null

///action/spell
/datum/mutation/embersnap
    power_path = /datum/action/cooldown/spell/conjure_item/embers

/datum/action/cooldown/spell/conjure_item/embers
	name = "Embersnap"
	desc = "Draws a fair bit of your body heat in order to create a mote of flame in your hand."
	button_icon_state = "ash"

	invocation = "snaps, igniting a flame in their hand."
	invocation_self_message = span_notice("You snap, lighting a flame in your hand.")
	invocation_type = INVOCATION_EMOTE

	cooldown_time = 1
	spell_requirements = NONE
	sound = 'sound/mobs/humanoids/human/snap/fingersnap1.ogg'

	item_type = /obj/item/embersnap_ember
	delete_old = TRUE
	delete_on_failure = TRUE

/datum/action/cooldown/spell/conjure_item/embers/after_cast(atom/cast_on)
	..()
	if(iscarbon(owner))
		owner.adjust_bodytemperature(-10)



///item
/obj/item/embersnap_ember
	name = "mote of flame"
	desc = "A little mote of flame."
	icon = 'icons/obj/cigarettes.dmi'
	icon_state = "zippo"
	inhand_icon_state = "zippo"
	worn_icon_state = "lighter"
	w_class = WEIGHT_CLASS_TINY
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	item_flags = NO_BLOOD_ON_ITEM
	slot_flags = null
	set_custom_materials(null)
	heat = HIGH_TEMPERATURE_REQUIRED - 100
	damtype = BURN
	force = 3
	hitsound = 'sound/items/tools/welder.ogg'
	attack_verb_continuous = list("burns", "singes")
	attack_verb_simple = list("burn", "singe")
	light_system = OVERLAY_LIGHT
	light_range = 2
	light_power = 1.3
	light_color = LIGHT_COLOR_FIRE
	light_on = TRUE
	var/lit = TRUE
	var/bypassDropMessage = FALSE

/obj/item/embersnap_ember/attack(mob/living/carbon/M, mob/living/carbon/user)
	if(!isliving(M))
		return

	if(M.ignite_mob())
		message_admins("[ADMIN_LOOKUPFLW(user)] set [key_name_admin(M)] on fire with [src] at [AREACOORD(user)]")
		user.log_message("set [key_name(M)] on fire with [src]", LOG_ATTACK)

	var/obj/item/cigarette/cig = help_light_cig(M)
	if(!cig || user.combat_mode)
		..()
		return

	if(cig.lit)
		to_chat(user, span_warning("The [cig] is already lit!"))
	if(M == user)
		cig.attackby(src, user)
	else
		cig.light(span_notice("[user] holds a careful, flaming digit out towards [M] and lights [cig]."))


/obj/item/embersnap_ember/attack_self(mob/living/user)
	if(!user.is_holding(src))
		return ..()

	if(!QDELETED(src))
		user.visible_message(
				span_notice("[user] snuffs out the [src] in [user.p_their()] hand."),
				span_notice("You snuff out the [src] in your hand, returning the mote's heat to your body.")
			)
		if(iscarbon(user))
			user.adjust_bodytemperature(10)
		qdel(src)

	..()

/obj/item/embersnap_ember/dropped(mob/user)
	if(!QDELETED(src))
		if(!bypassDropMessage)
			user.visible_message(
					span_notice("[user] dissolves the [src] in [user.p_their()] hand into the air around [user.p_them()]."),
					span_notice("You dissolve the [src] in your hand into the air.")
				)
			qdel(src)
		qdel(src)

	. = ..()

/obj/item/embersnap_ember/mob_can_equip(mob/living/user, slot)
	if(!user)
		return FALSE

	if(slot == ITEM_SLOT_LPOCKET || slot == ITEM_SLOT_RPOCKET || slot == ITEM_SLOT_HANDS)
		return TRUE

	return FALSE

/obj/item/embersnap_ember/on_equipped(mob/user, slot)
	if(!QDELETED(src))
		if(slot == ITEM_SLOT_LPOCKET || slot == ITEM_SLOT_RPOCKET)
			user.visible_message(
					span_notice("[user] coolly slips [user.p_their()] hand into [user.p_their()] pocket, snuffing out the [src] in [user.p_their()] hand in the process. Slick."),
					span_notice("You coolly slip your hand into your pocket, snuffing out the [src] in your hand in the process. Slick.")
				)
			qdel(src)

	if(slot == ITEM_SLOT_HANDS)
		return ..()

	return FALSE



/obj/item/embersnap_ember/on_enter_storage(datum/storage/container)
	if(QDELETED(src))
		return

	var/mob/M = container.parent
	if(ismob(M))
		to_chat(M,span_notice("The [src] sputters out as you attempt to store it away."))

	qdel(src)

/obj/item/embersnap_ember/on_thrown(mob/user)
	bypassDropMessage = TRUE
	if(!QDELETED(src))
		if(HAS_TRAIT(user, TRAIT_PACIFISM))
			user.visible_message(
				span_notice("[user] theatrically disperses the [src] in [user.p_their()] hand."),
				span_notice("You theatrically disperse the [src] in your hand.")
			)
			return ..()

		user.visible_message(
				span_danger("[user] disperses the [src] in [user.p_their()] hand into a shower of sparks!"),
				span_danger("You disperse the [src] in your hand into a shower of sparks!")
			)
		var/datum/effect_system/spark_spread/sparks = new
		sparks.set_up(1, 0, user)
		sparks.autocleanup = TRUE
		sparks.start()

	return ..()
