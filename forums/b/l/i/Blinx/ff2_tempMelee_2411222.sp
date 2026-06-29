#pragma semicolon 1

#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

public Plugin:myinfo = {
   name = "Freak Fortress 2: Temp Melee Weapon",
   author = "Blinx"
};

new String:weaponAttribs[64];
new String:weaponClass[64];
new thisWeaponIndex;

new String:reWeaponAttribs[64];
new String:reWeaponClass[64];
new reWeaponIndex;

public OnPluginStart2()
{
}

public Action:FF2_OnAbility2(index,const String:plugin_name[],const String:ability_name[],action)
{
   if (!strcmp(ability_name,"rage_tempMelee"))
      rage_tempMelee(ability_name, index);
}

stock SpawnWeapon(client,String:name[],index,level,qual,String:att[])
{
   new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
   TF2Items_SetClassname(hWeapon, name);
   TF2Items_SetItemIndex(hWeapon, index);
   TF2Items_SetLevel(hWeapon, level);
   TF2Items_SetQuality(hWeapon, qual);
   new String:atts[32][32];
   new count = ExplodeString(att, " ; ", atts, 32, 32);
   if (count > 0)
   {
      TF2Items_SetNumAttributes(hWeapon, count/2);
      new i2 = 0;
      for (new i = 0; i < count; i+=2)
      {
         TF2Items_SetAttribute(hWeapon, i2, StringToInt(atts[i]), StringToFloat(atts[i+1]));
         i2++;
      }
   }
   else
      TF2Items_SetNumAttributes(hWeapon, 0);
   if (hWeapon==INVALID_HANDLE)
      return -1;
   new entity = TF2Items_GiveNamedItem(client, hWeapon);
   CloseHandle(hWeapon);
   EquipPlayerWeapon(client, entity);
   return entity;
}

rage_tempMelee(const String:ability_name[], index)
{
   new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
   FF2_GetAbilityArgumentString(index, this_plugin_name, ability_name, 1, weaponAttribs, sizeof(weaponAttribs));
   FF2_GetAbilityArgumentString(index, this_plugin_name, ability_name, 2, weaponClass, sizeof(weaponClass));
   thisWeaponIndex = FF2_GetAbilityArgument(index, this_plugin_name, ability_name, 3);
   new Float:duration=FF2_GetAbilityArgumentFloat(index, this_plugin_name, ability_name, 4);
   
   TF2_RemoveWeaponSlot(Boss, TFWeaponSlot_Melee);
   SetEntPropEnt(Boss, Prop_Send, "m_hActiveWeapon", SpawnWeapon(Boss, weaponClass, thisWeaponIndex, 100, 8, weaponAttribs));
   
   new Handle:pack;
   CreateDataTimer(duration, normalMelee, pack, TIMER_DATA_HNDL_CLOSE);
   
   WritePackCell(pack, index);
   WritePackCell(pack, Boss);
}

public Action:normalMelee(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new index=ReadPackCell(pack);
	new Boss=ReadPackCell(pack);

	FF2_GetAbilityArgumentString(index, this_plugin_name, "rage_tempMelee", 5, reWeaponAttribs, sizeof(reWeaponAttribs));
	FF2_GetAbilityArgumentString(index, this_plugin_name, "rage_tempMelee", 6, reWeaponClass, sizeof(reWeaponClass));
	reWeaponIndex = FF2_GetAbilityArgument(index, this_plugin_name, "rage_tempMelee", 7);
	
	TF2_RemoveWeaponSlot(Boss, TFWeaponSlot_Melee);
	SetEntPropEnt(Boss, Prop_Send, "m_hActiveWeapon", SpawnWeapon(Boss, reWeaponClass, reWeaponIndex, 1, 5, reWeaponAttribs));
}