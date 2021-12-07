#include <tf2items>

public Action:TF2Items_OnGiveNamedItem(client, String:strClassName[], iItemDefinitionIndex, &Handle:hItemOverride)
{
  if (iItemDefinitionIndex == 452 || iItemDefinitionIndex == 453 || iItemDefinitionIndex == 454)
  {
    return Plugin_Handled
  }
  return Plugin_Continue
}