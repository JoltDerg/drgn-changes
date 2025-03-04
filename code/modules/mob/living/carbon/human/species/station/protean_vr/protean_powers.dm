#define PER_LIMB_STEEL_COST SHEET_MATERIAL_AMOUNT
////
//  One-part Refactor
////
/mob/living/carbon/human/proc/nano_partswap()
	set name = "Ref - Single Limb"
	set desc = "Allows you to replace and reshape your limbs as you see fit."
	set category = "Abilities"
	set hidden = TRUE

	if(stat)
		to_chat(src,"<span class='warning'>You must be awake and standing to perform this action!</span>")
		return

	if(!isturf(loc))
		to_chat(src,"<span class='warning'>You need more space to perform this action!</span>")
		return

	var/obj/item/organ/internal/nano/refactory/refactory = nano_get_refactory()
	//Missing the organ that does this
	if(!istype(refactory))
		to_chat(src,"<span class='warning'>You don't have a working refactory module!</span>")
		return

	//Already regenerating (RS Add)
	if(active_regen) //Global Protean Ability active check
		to_chat(src, "<span class='warning'>You are already refactoring!</span>")
		return
	//RS add end
	var/choice = tgui_input_list(src,"Pick the bodypart to change:", "Refactor - One Bodypart", species.has_limbs)
	if(!choice)
		return
	//Organ is missing, needs restoring
	if(!organs_by_name[choice] || istype(organs_by_name[choice], /obj/item/organ/external/stump)) //allows limb stumps to regenerate like removed limbs.
		if(refactory.get_stored_material(MAT_STEEL) < PER_LIMB_STEEL_COST)
			to_chat(src,"<span class='warning'>You're missing that limb, and need to store at least [PER_LIMB_STEEL_COST] steel to regenerate it.</span>")
			return
		var/regen = tgui_alert(src,"That limb is missing, do you want to regenerate it in exchange for [PER_LIMB_STEEL_COST] steel?","Regenerate limb?",list("Yes","No"))
		if(regen != "Yes")
			return
		//if(!refactory.use_stored_material(MAT_STEEL,PER_LIMB_STEEL_COST)) //RS Moved See line 56
		//	return //RS Moved
		if(organs_by_name[choice])
			var/obj/item/organ/external/oldlimb = organs_by_name[choice]
			oldlimb.removed()
			qdel(oldlimb)

		//var/mob/living/simple_mob/protean_blob/blob = nano_intoblob() ////RS Edit (Ability changed to not require blobbing)
		//RS Add
		active_regen = TRUE //Global Protean Ability active check
		to_chat(src, "<span class='danger'>Remain still while the process takes place! It will take 10 seconds.</span>")
		visible_message("<B>[src]</B>'s form begins to shift and ripple as if made of oil...")
		if(do_after(src,10 SECONDS))
		//RS Add End
			//RS edit (moved steel usage)
			if(!refactory.use_stored_material(MAT_STEEL,PER_LIMB_STEEL_COST))
				to_chat(src,"<span class='warning'>You do not have enough stored steel to do this.</span>")
				active_regen = FALSE //Global Protean Ability active chec
				return
			//RS Edit End (moved steel usage)
			var/list/limblist = species.has_limbs[choice]
			var/limbpath = limblist["path"]
			var/obj/item/organ/external/new_eo = new limbpath(src)
			organs_by_name[choice] = new_eo
			new_eo.robotize(synthetic ? synthetic.company : null) //Use the base we started with
			new_eo.sync_colour_to_human(src)
			// RS Add - Reapply lost markings
			var/list/dna_markings = dna.body_markings[choice]
			if(dna_markings)
				new_eo.markings = dna_markings.Copy()
			// RS Add End
			regenerate_icons()
		active_regen = FALSE //Global Protean Ability active check
		//nano_outofblob(blob) //RS Edit (Ability changed to not require blobbing)
		return

	//Organ exists, let's reshape it
	var/list/usable_manufacturers = list()
	for(var/company in chargen_robolimbs)
		var/datum/robolimb/M = chargen_robolimbs[company]
		if(!(choice in M.parts))
			continue
		if(species?.base_species in M.species_cannot_use)
			continue
		if(M.whitelisted_to && !(ckey in M.whitelisted_to))
			continue
		usable_manufacturers[company] = M
	if(!usable_manufacturers.len)
		return
	var/manu_choice = tgui_input_list(src, "Which manufacturer do you wish to mimic for this limb?", "Manufacturer for [choice]", usable_manufacturers)

	if(!manu_choice)
		return //Changed mind

	var/obj/item/organ/external/eo = organs_by_name[choice]
	if(!eo)
		return //Lost it meanwhile

	eo.robotize(manu_choice)
	visible_message("<B>[src]</B>'s [choice] loses its shape, then reforms.")
	update_icons_body()

////
//  Full Refactor
////
/mob/living/carbon/human/proc/nano_regenerate() //fixed the proc, it used to leave active_regen true.
	set name = "Ref - Whole Body"
	set desc = "Allows you to regrow limbs and replace organs, given you have enough materials."
	set category = "Abilities"
	set hidden = TRUE

	if(stat)
		to_chat(src,"<span class='warning'>You must be awake and standing to perform this action!</span>")
		return

	if(!isturf(loc))
		to_chat(src,"<span class='warning'>You need more space to perform this action!</span>")
		return

	var/obj/item/organ/internal/nano/refactory/refactory = nano_get_refactory()
	//Missing the organ that does this
	if(!istype(refactory))
		to_chat(src,"<span class='warning'>You don't have a working refactory module!</span>")
		return

	//Already regenerating
	if(active_regen) //Global Protean Ability active check
		to_chat(src, "<span class='warning'>You are already refactoring!</span>")
		return

	var/swap_not_rebuild = tgui_alert(src,"Do you want to rebuild, or reshape?","Rebuild or Reshape",list("Reshape","Cancel","Rebuild"))
	if(swap_not_rebuild == "Cancel")
		return
	if(swap_not_rebuild == "Reshape")
		var/list/usable_manufacturers = list()
		for(var/company in chargen_robolimbs)
			var/datum/robolimb/M = chargen_robolimbs[company]
			if(!(BP_TORSO in M.parts))
				continue
			if(species?.base_species in M.species_cannot_use)
				continue
			if(M.whitelisted_to && !(ckey in M.whitelisted_to))
				continue
			usable_manufacturers[company] = M
		if(!usable_manufacturers.len)
			return
		var/manu_choice = tgui_input_list(src, "Which manufacturer do you wish to mimic?", "Manufacturer", usable_manufacturers)

		if(!manu_choice)
			return //Changed mind
		if(!organs_by_name[BP_TORSO])
			return //Ain't got a torso!

		var/obj/item/organ/external/torso = organs_by_name[BP_TORSO]
		to_chat(src, "<span class='danger'>Remain still while the process takes place! It will take 5 seconds.</span>")
		visible_message("<B>[src]</B>'s form collapses into an amorphous blob of black ichor...")

		//var/mob/living/simple_mob/protean_blob/blob = nano_intoblob() //RS Edit (Ability changed to not require blobbing)
		active_regen = TRUE //Global Protean Ability active check
		if(do_after(src,5 SECONDS))
			/*if(refactory.get_stored_material(MAT_STEEL) < refactory.max_storage) //RS Edit changed to not take steel untill operation completed
				to_chat(src, "<span class='warning'>You need to be maxed out on normal metal to do this!</span>")
				active_regen = FALSE //global protean ability active check
				return
			*/ //Check not needed?
			synthetic = usable_manufacturers[manu_choice]
			torso.robotize(manu_choice) //Will cascade to all other organs.
			// RS Add - Reapply lost markings
			for(var/organname in organs_by_name)
				var/list/dna_markings = dna.body_markings[organname]
				if(dna_markings)
					var/obj/item/organ/external/EO = organs_by_name[organname]
					EO.markings = dna_markings.Copy()
			// RS Add End
			//regenerate_icons() // RS Remove - Included as part of set color below
			shapeshifter_set_colour(rgb(r_skin,g_skin,b_skin)) // RS Add
			visible_message("<B>[src]</B>'s form reshapes into a new one...")
		active_regen = FALSE
		//nano_outofblob(blob) //RS Edit (Ability changed to not require blobbing)
		return



	var/delay_length = round(active_regen_delay * species.active_regen_mult)
	active_regen = TRUE //Global Protean Ability active check

	//var/mob/living/simple_mob/protean_blob/blob = nano_intoblob() //RS Edit (Ability changed to not require blobbing)
	if(stat != DEAD && refactory)
		var/list/holder = refactory.materials
		if(refactory.get_stored_material(MAT_STEEL) < refactory.max_storage) //RS Edit
			to_chat(src,"<span class='warning'>You do not have enough stored steel to do this.</span>")
			active_regen = FALSE //Global Protean Ability active check
			return
		to_chat(src, "<span class='danger'>Remain still while the process takes place! It will take [delay_length/10] seconds.</span>")
		visible_message("<B>[src]</B>'s form begins to shift and ripple as if made of oil...")
		if(do_after(src, delay_length, null, 0))
			//RS Edit (Changed ability to not heal all damage (code taken from Organic 'Regenerate' Ability))
			// Replace completely missing limbs.
			if(!refactory.use_stored_material(MAT_STEEL,refactory.max_storage))
				return
			for(var/limb_type in src.species.has_limbs)
				var/obj/item/organ/external/E = src.organs_by_name[limb_type]

				if(E && E.disfigured)
					E.disfigured = 0
				if(E && (E.is_stump() || (E.status & (ORGAN_DESTROYED|ORGAN_DEAD|ORGAN_MUTATED))))
					E.removed()
					qdel(E)
					E = null
				if(!E)
					var/list/organ_data = src.species.has_limbs[limb_type]
					var/limb_path = organ_data["path"]
					var/obj/item/organ/O = new limb_path(src)
					organ_data["descriptor"] = O.name
					to_chat(src, "<span class='notice'>You feel a shifting sensation as your [O.name] reconsitutes.</span>")



			var/mob/living/carbon/human/H = src
			for(var/obj/item/organ/O as anything in H.internal_organs)
				// Fix internal damage
				if(O.damage > 0)
					O.damage = 0
				// If not damaged, but dead, fix it
				else if(O.status & ORGAN_DEAD)
					O.status &= ~ORGAN_DEAD //Unset dead if we repaired it entirely
			handle_organs() // Update everything
			//RS Edit End
			update_icons_body()
			var/obj/item/organ/external/torso = organs_by_name[BP_TORSO]
			torso.robotize(synthetic?.company) // RS Edit: Keep synth manufacturer if we can
			LAZYCLEARLIST(blood_DNA)
			LAZYCLEARLIST(feet_blood_DNA)
			blood_color = null
			feet_blood_color = null
			// RS Add - Reapply lost markings
			for(var/organname in organs_by_name)
				var/list/dna_markings = dna.body_markings[organname]
				if(dna_markings)
					var/obj/item/organ/external/EO = organs_by_name[organname]
					EO.markings = dna_markings.Copy()
			// RS Add End
			//regenerate_icons() // RS Remove - Included as part of set color below
			shapeshifter_set_colour(rgb(r_skin,g_skin,b_skin)) // RS Add
			var/obj/item/organ/internal/nano/refactory/new_refactory = locate() in internal_organs
			if(!new_refactory)
				log_debug("[src] protean-regen'd but lacked a refactory when done.")
			else
				new_refactory.materials = holder

			to_chat(src, "<span class='notice'>Your refactoring is complete!</span>")
		else
			to_chat(src, "<span class='critical'>Your refactoring is interrupted!</span>")

	else
		to_chat(src, "<span class='critical'>Your refactoring has failed!</span>")
	active_regen = FALSE //Global Protean Ability active check
	//nano_outofblob(blob)


////
//  Storing metal
////
/mob/living/carbon/human/proc/nano_metalnom()
	set name = "Ref - Store Metals"
	set desc = "If you're holding a stack of material, you can consume some and store it for later."
	set category = "Abilities"
	set hidden = TRUE

	var/obj/item/organ/internal/nano/refactory/refactory = nano_get_refactory()
	//Missing the organ that does this
	if(!istype(refactory))
		to_chat(src,"<span class='warning'>You don't have a working refactory module!</span>")
		return

	var/held = get_active_hand()
	if(!istype(held,/obj/item/stack/material))
		to_chat(src,"<span class='warning'>You aren't holding a stack of materials in your active hand...!</span>")
		return

	var/obj/item/stack/material/matstack = held
	var/substance = matstack.material.name
	var allowed = FALSE
	for(var/material in PROTEAN_EDIBLE_MATERIALS)
		if(material == substance) allowed = TRUE
	if(!allowed)
		to_chat(src,"<span class='warning'>You can't process [substance]!</span>")
		return //Only a few things matter, the rest are best not cluttering the lists.

	var/howmuch = tgui_input_number(src,"How much do you want to store? (0-[matstack.get_amount()])","Select amount",null,matstack.get_amount(),0)
	if(!howmuch || matstack != get_active_hand() || howmuch > matstack.get_amount())
		return //Quietly fail

	var/actually_added = refactory.add_stored_material(substance,howmuch*matstack.perunit)
	matstack.use(CEILING((actually_added/matstack.perunit), 1))
	if(actually_added && actually_added < howmuch)
		to_chat(src,"<span class='warning'>Your refactory module is now full, so only [actually_added] units were stored.</span>")
		visible_message("<span class='notice'>[src] nibbles some of the [substance] right off the stack!</span>")
	else if(actually_added)
		to_chat(src,"<span class='notice'>You store [actually_added] units of [substance].</span>")
		visible_message("<span class='notice'>[src] devours some of the [substance] right off the stack!</span>")
	else
		to_chat(src,"<span class='notice'>You're completely capped out on [substance]!</span>")

////
//  Blob Form
////
/mob/living/carbon/human/proc/nano_blobform()
	set name = "Toggle Blobform"
	set desc = "Switch between amorphous and humanoid forms."
	set category = "Abilities"
	set hidden = TRUE

	var/atom/movable/to_locate = temporary_form || src
	if(!isturf(to_locate.loc))
		to_chat(to_locate,"<span class='warning'>You need more space to perform this action!</span>")
		return

	//Blob form
	if(temporary_form)
		//RS Edit (removed un-blob health requirement)
		/*if(health < maxHealth*0.5)
			to_chat(temporary_form,"<span class='warning'>You need to regenerate more nanites first!</span>")
		else */
		//RS Edit End
		if(temporary_form.stat)
			to_chat(temporary_form,"<span class='warning'>You can only do this while not stunned.</span>")
		else
			nano_outofblob(temporary_form)


	//Human form
	else if(stat || paralysis || stunned || restrained()) //RS Edit (no blobbing while arrested/unconcious)
		to_chat(src,"<span class='warning'>You can only do this while not stunned.</span>")
		return
	else
		//RS Edit (no blobbing while arrested/unconcious)
		if(active_regen == FALSE) // Prevents you from accidently blobbing while an ability is running
			var/confirm_blob = tgui_alert(src,"Are you sure you want to blob?","Yes or No",list("Yes","No"))//Rs add (more accidental blobbing prevention)
			if(confirm_blob == "No")
				return
			if(confirm_blob == "Yes")
				if(stat || paralysis || stunned || restrained()) //Double check to make sure we didnt get KO'd during our confirmation text
					to_chat(src,"<span class='warning'>Blobbing interrupted.</span>")
					active_regen = FALSE //Global Protean Ability active chec
					return
				active_regen = TRUE;
				to_chat(src,"<span class='notice'>Your form starts to shift as you begin to collapse into a gooey blob.</span>")
				visible_message("<b>[src.name]</b>Collapses into a gooey blob!")
				nano_intoblob()
			active_regen = FALSE
			//RS Edit End


////
//  Change fitting
////
/mob/living/carbon/human/proc/nano_change_fitting()
	set name = "Change Species Fit"
	set desc = "Tweak your shape to change what suits you fit into (and their sprites!)."
	set category = "Abilities"

	if(stat || paralysis || stunned || restrained()) //RS Edit (no Abilities while unconcious/arrested)
		to_chat(src,"<span class='warning'>You must be awake and standing to perform this action!</span>")
		return

	var/new_species = tgui_input_list(usr, "Please select a species to emulate.", "Shapeshifter Body", GLOB.playable_species)
	if(new_species)
		species?.base_species = new_species // Really though you better have a species
		regenerate_icons() //Expensive, but we need to recrunch all the icons we're wearing
///// RS Addition/Edit (ability toggle for healing)
//	Passive Heal
////
/mob/living/carbon/human/proc/nano_healing()
	set name = "Powered Healing"
	set category = "Abilities"
	set hidden = TRUE
	var/mob/living/user = temporary_form || src

	if(!istype(species,/datum/species/protean)) // ???
		return
	var/datum/species/protean/S = species
	//to_chat(user,"<span class='warning'>Ability Activated...</span>")
	var/obj/item/organ/internal/nano/refactory/refactory = nano_get_refactory()
	if(!istype(refactory))
		to_chat(user,"<span class='warning'>You don't have a working refactory module!</span>")
		return
	//else
		//to_chat(user,"<span class='warning'>Refactory Detected...</span>")
	//if(!temporary_form)
		//to_chat(user,"<span class='warning'>Is human form...</span>")
	if(!active_regen) //Global Protean Ability active check
		if(S.prot_healing_allowed == FALSE)
			if(refactory.get_stored_material(MAT_STEEL) < 100)
				to_chat(user,"<span class='warning'>You do not have enough stored steel to do this.</span>")
				return
			if(user.nutrition <= 150)
				to_chat(user,"<span class='warning'>Not enough power to enable healing routines...</span>")
				return
			if(!src.getActualBruteLoss() && !src.getActualFireLoss())
				to_chat(user,"<span class='warning'>You're not injured...</span>")
				return
			if(!do_after(user,5 SECONDS))
				to_chat(user,"<span class='warning'>You need to stand still while diagnosing...</span>")
				return
			to_chat(user, "<span class='notice'>Regeneration Enabled.</span>")
			S.prot_healing_allowed = TRUE
		else
			to_chat(user, "<span class='notice'>Regeneration Disabled.</span>")
			S.prot_healing_allowed = FALSE
	else
		to_chat(user,"<span class='warning'>You Are already performing a regeneration action.</span>")

// RS Addition/Edit End

////
//  Change size
////
/mob/living/carbon/human/proc/nano_set_size()
	set name = "Adjust Volume"
	set category = "Abilities"
	set hidden = TRUE

	var/mob/living/user = temporary_form || src

	var/obj/item/organ/internal/nano/refactory/refactory = nano_get_refactory()
	//Missing the organ that does this
	if(!istype(refactory))
		to_chat(user,"<span class='warning'>You don't have a working refactory module!</span>")
		return

	var/nagmessage = "Adjust your mass to be a size between 25 to 200% (or between 1 to 600% in dorms area)." //RS Edit Removed reference to steel requirement
	var/new_size = tgui_input_number(user, nagmessage, "Pick a Size", user.size_multiplier*100, 600, 1)
	if(!new_size || !size_range_check(new_size))
		return

	var/size_factor = new_size/100
	//RS Removed (steel requirement/refund for scaling, was abuseable)
	user.resize(size_factor, ignore_prefs = TRUE)
	user.visible_message("<span class='notice'>Black mist swirls around [user] as they change size.</span>")

/// /// /// A helper to reuse
/mob/living/proc/nano_get_refactory(obj/item/organ/internal/nano/refactory/R)
	if(istype(R))
		if(!(R.status & ORGAN_DEAD))
			return R
	return

/mob/living/simple_mob/protean_blob/nano_get_refactory()
	if(refactory)
		return ..(refactory)
	if(humanform)
		return humanform.nano_get_refactory()

/mob/living/carbon/human/nano_get_refactory()
	return ..(locate(/obj/item/organ/internal/nano/refactory) in internal_organs)



/// /// /// Ability objects for stat panel
/obj/effect/protean_ability
	name = "Activate"
	desc = ""
	icon = 'icons/mob/species/protean/protean_powers.dmi'
	var/ability_name
	var/to_call

/obj/effect/protean_ability/proc/atom_button_text()
	return src

/obj/effect/protean_ability/Click(var/location, var/control, var/params)
	var/list/clickprops = params2list(params)
	var/opts = clickprops["shift"]

	if(opts)
		to_chat(usr,"<span class='notice'><b>[ability_name]</b> - [desc]</span>")
	else
		//Humanform using it
		if(ishuman(usr))
			do_ability(usr)
		//Blobform using it
		else
			var/mob/living/simple_mob/protean_blob/blob = usr
			do_ability(blob.humanform)

/obj/effect/protean_ability/proc/do_ability(var/mob/living/L)
	if(istype(L))
		call(L,to_call)()
	return FALSE

/// The actual abilities
//RS Add (passive heal toggle ability)
/obj/effect/protean_ability/passive_heal
	ability_name = "Toggle Regeneration"
	desc = "Consume steel and energy to heal yourself slowly."
	icon = 'icons/mob/radial_vr.dmi'
	icon_state = "tl_plus"
	to_call = /mob/living/carbon/human/proc/nano_healing
//RS Add End
/obj/effect/protean_ability/into_blob
	ability_name = "Toggle Blobform"
	desc = "Discard your shape entirely, changing to a low-energy blob that can fit into small spaces. You'll consume steel to repair yourself in this form."
	icon = 'icons/mob/species/protean/protean_powers.dmi' //RS Add
	icon_state = "blob"
	to_call = /mob/living/carbon/human/proc/nano_blobform

/obj/effect/protean_ability/change_volume
	ability_name = "Change Volume"
	desc = "Alter your size by consuming steel to produce additional nanites, or regain steel by reducing your size and reclaiming them."
	icon = 'icons/mob/species/protean/protean_powers.dmi' //RS Add
	icon_state = "volume"
	to_call = /mob/living/carbon/human/proc/nano_set_size

/obj/effect/protean_ability/reform_limb
	ability_name = "Ref - Single Limb"
	desc = "Rebuild or replace a single limb, assuming you have 2000 steel."
	icon = 'icons/mob/species/protean/protean_powers.dmi' //RS Add
	icon_state = "limb"
	to_call = /mob/living/carbon/human/proc/nano_partswap

/obj/effect/protean_ability/reform_body
	ability_name = "Ref - Whole Body"
	desc = "Rebuild your entire body into whatever design you want, assuming you have 10,000 metal."
	icon = 'icons/mob/species/protean/protean_powers.dmi' //RS Add
	icon_state = "body"
	to_call = /mob/living/carbon/human/proc/nano_regenerate

/obj/effect/protean_ability/metal_nom
	ability_name = "Ref - Store Metals"
	desc = "Store the metal you're holding. Your refactory can only store steel, and all other metals will be converted into nanites ASAP for various effects."
	icon = 'icons/mob/species/protean/protean_powers.dmi' //RS Add
	icon_state = "metal"
	to_call = /mob/living/carbon/human/proc/nano_metalnom

#undef PER_LIMB_STEEL_COST
