//Keeps track of weapons created and saves their id for easy look up. Requires SDKHooks.
new Handle:hWeaponsIDArray = INVALID_HANDLE;
new Handle:hWeaponEntityArray = INVALID_HANDLE;

stock CheckWeaponArrays()
{
	if(hWeaponsIDArray == INVALID_HANDLE)
		hWeaponsIDArray = CreateArray();
	else
		ClearArray(hWeaponsIDArray);
		
	if(hWeaponEntityArray == INVALID_HANDLE)
		hWeaponEntityArray = CreateArray();
	else
		ClearArray(hWeaponEntityArray);
	
	decl String:name[WEAPONARRAYSIZE];
	for (new i = MaxClients; i <= GetMaxEntities(); i++)
	{
		if (IsValidEdict(i) && IsValidEntity(i))
		{
			GetEdictClassname(i, name, sizeof(name));
			if((strncmp(name, "weapon_", 7, false) == 0 || strncmp(name, "item_", 5, false) == 0))
			{
				new WeaponID:id = Restrict_GetWeaponIDExtended(name);
				new index = FindValueInArray(hWeaponEntityArray, i);
				if(id != WEAPON_NONE && index == -1)
				{
					PushArrayCell(hWeaponsIDArray, _:id);
					PushArrayCell(hWeaponEntityArray, i); 
				}
			}
		}
	}
}
public OnEntityCreated(entity, const String:classname[])
{
	if(hWeaponsIDArray == INVALID_HANDLE || hWeaponEntityArray == INVALID_HANDLE)
		return;
	
	
	if(StrContains(classname, "weapon_", false) != -1 || StrContains(classname, "item_", false) != -1)
	{
		new WeaponID:id = GetWeaponID(classname);
		
		if(id == WEAPON_NONE || FindValueInArray(hWeaponEntityArray, entity) != -1)
			return;
		
		PushArrayCell(hWeaponsIDArray, _:id);
		PushArrayCell(hWeaponEntityArray, entity); 
	}
}
public OnEntityDestroyed(entity)
{	
	if(hWeaponsIDArray == INVALID_HANDLE || hWeaponEntityArray == INVALID_HANDLE)
		return;
	
	new index = FindValueInArray(hWeaponEntityArray, entity);
	if(index != -1)
	{
		RemoveFromArray(hWeaponEntityArray, index);
		RemoveFromArray(hWeaponsIDArray, index);
	}
}
stock WeaponID:GetWeaponIDFromEnt(entity)
{
	if(!IsValidEdict(entity))
		return WEAPON_NONE;
	
	new index = FindValueInArray(hWeaponEntityArray, entity);
	if(index != -1)
	{
		return GetArrayCell(hWeaponsIDArray, index);
	}
	//Just incase code
	new String:classname[WEAPONARRAYSIZE];
	GetEdictClassname(entity, classname, sizeof(classname));
	if(StrContains(classname, "weapon_", false) != -1 || StrContains(classname, "item_", false) != -1)
	{
		new WeaponID:id = GetWeaponID(classname);
		
		if(id == WEAPON_NONE)
			return WEAPON_NONE;
		
		PushArrayCell(hWeaponsIDArray, _:id);
		PushArrayCell(hWeaponEntityArray, entity);
		
		return id;
	}
	
	return WEAPON_NONE;
}