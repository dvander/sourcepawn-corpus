#include <tf2>
#include <tf2_stocks>
#include <sourcemod>
#include <sdktools>
#include <tf2items>

public Action:TF2Items_OnGiveNamedItem(iClient, String:strClassName[], iItemDefinitionIndex, &Handle:hItemOverride)
{
  PrintToChatAll("GiveNamedItem(%i, %s)", iClient, strClassName)
  if (StrEqual(strClassName, "tf_weapon_syringegun_medic"))
  {
    new Handle:hTest = TF2Items_CreateItem(OVERRIDE_ATTRIBUTES + OVERRIDE_ITEM_QUALITY)
    TF2Items_SetNumAttributes(hTest, 2)
    TF2Items_SetAttribute(hTest, 0,  17, 0.1)
    TF2Items_SetAttribute(hTest, 1,   4, 2.0)
    TF2Items_SetQuality(hTest, 6)
    hItemOverride = hTest
    return Plugin_Changed
  }
  else
  {
    new Handle:hTest = TF2Items_CreateItem(OVERRIDE_ITEM_QUALITY)
    TF2Items_SetQuality(hTest, 6)
    hItemOverride = hTest
    return Plugin_Changed
  }
  return Plugin_Continue       // Return Plugin_Continue to leave them intact
}
