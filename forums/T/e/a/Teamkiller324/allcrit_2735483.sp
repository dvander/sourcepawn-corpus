public	Plugin	myinfo	= 	{
	name		=	"[TF2] Allcrits",
	author		=	"blendmaster345",
	description	=	"Make every hit a crit",
	version		=	"1.0.1",
	url			=	"http://sourcemod.net/"
};
/////////////////////////////////
ConVar	IsAllCritOn;
/////////////////////////////////
public	void	OnPluginStart()	{
	IsAllCritOn	=	CreateConVar("sm_allcrit_enable",	"1",	"Enable/Disable All Crits");
}
/////////////////////////////////
public	Action	TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool result)	{
	if(!GetConVarBool(IsAllCritOn))
		result	=	false;
	else {
		result	=	true;  //100% crits
		return	Plugin_Handled;  //Stop TF2 from doing anything about it
	}
	return	Plugin_Continue;
}