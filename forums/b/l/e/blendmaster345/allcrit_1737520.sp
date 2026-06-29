public Plugin:myinfo = 
{
	name = "TF2 All Crit",
	author = "blendmaster345",
	description = "Make every hit a crit",
	version = "1.0",
	url = "http://sourcemod.net/"
};
/////////////////////////////////
new Handle:IsAllCritOn;
/////////////////////////////////
public OnPluginStart()
{
	IsAllCritOn = CreateConVar("sm_allcrit_enable","1","Enable/Disable All Crits");
}
/////////////////////////////////
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (!GetConVarBool(IsAllCritOn)){
		result = false;
		}
	else {
		result = true;  //100% crits
		return Plugin_Handled;  //Stop TF2 from doing anything about it
		}
}