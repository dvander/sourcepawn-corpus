#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define 	MAX_WEAPON_NAME 	80
#define 	MAX_WEAPONS			48

public OnPluginStart()
{
	RegAdminCmd("sm_give_weapon", Cmd_GiveWeapon, ADMFLAG_GENERIC, "Give a player a named weapon without switching to it");
}

public Action:Cmd_GiveWeapon(client, args)
{
	if (args != 1)
	{
		return Plugin_Handled;
	}
	
	new String:arg1[MAX_WEAPON_NAME];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	Client_GiveWeapon(client, arg1, false);
	
	return Plugin_Continue;
}

/**
 * Gives a client a weapon.
 *
 * @param client		Client Index.
 * @param className		Weapon Classname String.
 * @param switchTo		If set to true, the client will switch the active weapon to the new weapon.
 * @return				Entity Index of the given weapon on success, INVALID_ENT_REFERENCE on failure.
 */
Client_GiveWeapon(client, const String:className[], bool:switchTo=true)
{
	new weapon = Client_GetWeapon(client, className);
	
	if (weapon == INVALID_ENT_REFERENCE) {
		weapon = Weapon_CreateForOwner(client, className);
		
		if (weapon == INVALID_ENT_REFERENCE) {
			return INVALID_ENT_REFERENCE;
		}
	}

	Client_EquipWeapon(client, weapon, switchTo);

	return weapon;
}

/**
 * Equips (attaches) a weapon to a client.
 *
 * @param client		Client Index.
 * @param weapon		Entity Index of the weapon.
 * @param switchTo		If true, the client will switch to that weapon (make it active).
 * @noreturn
 */
Client_EquipWeapon(client, weapon, bool:switchTo=false)
{
	EquipPlayerWeapon(client, weapon);
	
	if (switchTo) {
		Client_SetActiveWeapon(client, weapon);
	}
}

/**
 * Changes the active/current weapon of a player by Index.
 * Note: No changing animation will be played !
 *
 * @param client		Client Index.
 * @param weapon		Index of a valid weapon.
 * @noreturn
 */
Client_SetActiveWeapon(client, weapon)
{
	SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", weapon);
	ChangeEdictState(client, FindDataMapOffs(client, "m_hActiveWeapon"));
}

/**
 * Create's a weapon and spawns it in the world at the specified location.
 * 
 * @param className		Classname String of the weapon to spawn
 * @param absOrigin		Absolute Origin Vector where to spawn the weapon.
 * @param absAngles		Absolute Angles Vector.
 * @return				Weapon Index of the created weapon or INVALID_ENT_REFERENCE on error.
 */
Weapon_CreateForOwner(client, const String:className[])
{
	new Float:absOrigin[3], Float:absAngles[3];
	Entity_GetAbsOrigin(client, absOrigin);
	Entity_GetAbsAngles(client, absAngles);
	
	new weapon = Weapon_Create(className, absOrigin, absAngles);
	
	if (weapon == INVALID_ENT_REFERENCE) {
		return INVALID_ENT_REFERENCE;
	}
	
	Entity_SetOwner(weapon, client);
	
	return weapon;
}

/**
 * Create's a weapon and spawns it in the world at the specified location.
 * 
 * @param className		Classname String of the weapon to spawn
 * @param absOrigin		Absolute Origin Vector where to spawn the weapon.
 * @param absAngles		Absolute Angles Vector.
 * @return				Weapon Index of the created weapon or INVALID_ENT_REFERENCE on error.
 */
Weapon_Create(const String:className[], Float:absOrigin[3], Float:absAngles[3])
{
	new weapon = Entity_Create(className);
	
	if (weapon == INVALID_ENT_REFERENCE) {
		return INVALID_ENT_REFERENCE;
	}
	
	Entity_SetAbsOrigin(weapon, absOrigin);
	Entity_SetAbsAngles(weapon, absAngles);
	
	DispatchSpawn(weapon);
	
	return weapon;
}

/**
 *  Creates an entity by classname.
 *
 * @param className			Classname String.
 * @param ForceEdictIndex	Edict Index to use.
 * @return 					Entity Index or INVALID_ENT_REFERENCE if the slot is already in use.
 */
Entity_Create(const String:className[], ForceEdictIndex=-1)
{
	if (ForceEdictIndex != -1 && Entity_IsValid(ForceEdictIndex)) {
		return INVALID_ENT_REFERENCE;
	}

	return CreateEntityByName(className, ForceEdictIndex);
}

/**
 * Checks if an entity is valid and exists.
 *
 * @param entity		Entity Index.
 * @return				True if the entity is valid, false otherwise.
 */
Entity_IsValid(entity)
{
	return IsValidEntity(entity);
}

/**
 * Sets the Absolute Origin (position) of an entity.
 *
 * @param entity			Entity index.
 * @param vec				3 dimensional vector array.
 * @noreturn
 */
Entity_SetAbsOrigin(entity, Float:vec[3])
{
	// We use TeleportEntity to set the origin more safely
	// Todo: Replace this with a call to UTIL_SetOrigin() or CBaseEntity::SetLocalOrigin()
	TeleportEntity(entity, vec, NULL_VECTOR, NULL_VECTOR);
}

/**
 * Sets the Angles of an entity
 *
 * @param entity			Entity index.
 * @param vec				3 dimensional vector array.
 * @noreturn
 */ 
Entity_SetAbsAngles(entity, Float:vec[3])
{
	// We use TeleportEntity to set the angles more safely
	// Todo: Replace this with a call to CBaseEntity::SetLocalAngles()
	TeleportEntity(entity, NULL_VECTOR, vec, NULL_VECTOR);
}

/**
 * Gets the Absolute Origin (position) of an entity.
 *
 * @param entity			Entity index.
 * @param vec				3 dimensional vector array.
 * @noreturn
 */
Entity_GetAbsOrigin(entity, Float:vec[3])
{
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vec);
}

/**
 * Gets the Angles of an entity
 *
 * @param entity			Entity index.
 * @param vec				3 dimensional vector array.
 * @noreturn
 */ 
Entity_GetAbsAngles(entity, Float:vec[3])
{
	GetEntPropVector(entity, Prop_Data, "m_angAbsRotation", vec);
}

/**
 * Sets the owner of an entity.
 * For example the owner of a weapon entity.
 *
 * @param entity			Entity index.
 * @noreturn
 */
Entity_SetOwner(entity, newOwner)
{
	SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", newOwner);
}

/**
 * Gets the weapon of a client by the weapon's classname.
 *
 * @param client 		Client Index.
 * @param className		Classname of the weapon.
 * @return				Entity index on success or INVALID_ENT_REFERENCE.
 */
Client_GetWeapon(client, const String:className[])
{
	new offset = Client_GetWeaponsOffset(client) - 4;
	
	for (new i=0; i < MAX_WEAPONS; i++) {
		offset += 4;
		
		new weapon = GetEntDataEnt2(client, offset);
		
		if (!Weapon_IsValid(weapon)) {
			continue;
		}
		
		if (Entity_ClassNameMatches(weapon, className)) {
			return weapon;
		}
	}
	
	return INVALID_ENT_REFERENCE;
}

/**
 * Checks if an entity matches a specific entity class.
 *
 * @param entity		Entity Index.
 * @param class			Classname String.
 * @return				True if the classname matches, false otherwise.
 */
bool:Entity_ClassNameMatches(entity, const String:className[], partialMatch=false)
{
	new String:entity_className[64];
	Entity_GetClassName(entity, entity_className, sizeof(entity_className));
	
	if (partialMatch) {
		return (StrContains(entity_className, className) != -1);
	}
	
	return StrEqual(entity_className, className);
}

/**
 * Gets the Classname of an entity.
 * This is like GetEdictClassname(), except it works for ALL
 * entities, not just edicts.
 *
 * @param entity			Entity index.
 * @param buffer			Return/Output buffer.
 * @param size				Max size of buffer.
 * @return					
 */
Entity_GetClassName(entity, String:buffer[], size)
{
	GetEntPropString(entity, Prop_Data, "m_iClassname", buffer, size);
	
	if (buffer[0] == '\0') {
		return false;
	}
	
	return true;
}

/**
 * Checks whether the entity is a valid weapon or not.
 * 
 * @param weapon		Weapon Entity.
 * @return				True if the entity is a valid weapon, false otherwise.
 */
Weapon_IsValid(weapon)
{
	if (!IsValidEdict(weapon)) {
		return false;
	}
	
	return Entity_ClassNameMatches(weapon, "weapon_", true);
}

/**
 * Gets the offset for a client's weapon list (m_hMyWeapons).
 * The offset will saved globally for optimization.
 *
 * @param client		Client Index.
 * @return				Weapon list offset or -1 on failure.
 */
Client_GetWeaponsOffset(client)
{
	static offset = -1;
	
	if (offset == -1) {
		offset = FindDataMapOffs(client, "m_hMyWeapons");
	}
	
	return offset;
}