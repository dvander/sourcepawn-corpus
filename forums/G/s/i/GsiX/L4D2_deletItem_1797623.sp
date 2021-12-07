#include <sourcemod>
#include <sdktools>
#define VERSION "0.0"
new Handle:z_rangeDelete;
new const String:ItemDeleteList[][] = {
	//add item start here.
	//follow below example.
	
	//add item end here.
	"weapon_machete",
	"weapon_katana",
	"weapon_hunting_knife",
	"weapon_besball_bat",
	"weapon_cricket_bat",
	"weapon_crowbar",
	"weapon_electric_guitar",
	"weapon_fireaxe",
	"weapon_frying_pan",
	"weapon_golfclub",
	"weapon_riotshield",
	"weapon_tonfa",
	"weapon_melee",
	"weapon_smg_mp5",
	"weapon_smg",
	"weapon_smg_silenced",
	"weapon_shotgun_chrome",
	"weapon_pumpshotgun",
	"weapon_hunting_rifle",
	"weapon_pistol",
	"weapon_pistol_magnum"
};
public Plugin:myinfo = {
	name = "Delete Item",
	author = "GsiX",
	description = "Delete item near admin",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=1797623#post1797623"
}
public OnPluginStart() {
	CreateConVar("delete_near",VERSION,"Delete Item Version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	// my fellow friend, the value of max range is 200.0, in case you want to increase it.
	z_rangeDelete = CreateConVar("l4d2_delete_range", "200.0", "Our max range of scaning", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	RegConsoleCmd("sm_dlt", CmdDeleteThat, "Delete single item on cross hair");
	RegConsoleCmd("sm_dltall", CmdDeleteItem, "Will delete any item near u");
}
public Action:CmdDeleteItem(client, args) {
	if (!IsAccessGranted(client)) return Plugin_Handled;
	decl Float:targetPos[3], Float:playerPos[3];
	new counTER = 0;
	new Float:distancE;
	new Float:ourMaxRange = GetConVarFloat(z_rangeDelete);
	new EntCount = GetEntityCount();
	new String:EdictName[256];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", playerPos);
	for (new i = 0; i <= EntCount; i++)	{
		if (IsValidEntity(i)) {
			GetEdictClassname(i, EdictName, sizeof(EdictName));
			for(new j=0; j < sizeof(ItemDeleteList); j++) {
				if(StrContains(EdictName, ItemDeleteList[j], false) != -1) {
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", targetPos)
					distancE = GetVectorDistance(targetPos,playerPos);
					if (distancE < ourMaxRange)	{
						AcceptEntityInput(i, "Kill");
						counTER = counTER+1;
					}
				}
			}
		}
	}
	if(counTER > 0)	PrintToChat(client, "[DELETE]: %i item(s) removed!", counTER);
	return Plugin_Handled;
}
public Action:CmdDeleteThat(client, args) {
	if (!IsAccessGranted(client)) return Plugin_Handled;
	new pObject = GetClientAimTarget(client, false);
	if (pObject == -1){
		ReplyToCommand( client, "[DELET]: Null entity!" );
		return Plugin_Handled;
	}
	if (pObject > 0 && pObject < MaxClients) {
		decl String:pObjectName[MAX_NAME_LENGTH];
		GetClientName(pObject, pObjectName, sizeof(pObjectName));
		ReplyToCommand( client, "[DELETE]: Unable to delete player %s", pObjectName);
		return Plugin_Handled;
	}
	else {
		decl String:pObjectName[60];
		GetEntityClassname(pObject, pObjectName, sizeof(pObjectName));
		RemoveEdict(pObject);
		ReplyToCommand(client, "[DELETE]: Entity (%s) deleted!", pObjectName);
		return Plugin_Handled;
	}
}
//only admin do this
bool:IsAccessGranted( client ) {
	new bool:granted = false;
	new AdminId:h_idAdmin = GetUserAdmin(client);
	if ((!IsValidEntity(client)) || (IsFakeClient(client))) return granted;
	if (GetAdminFlag(h_idAdmin, Admin_Reservation) || GetAdminFlag(h_idAdmin, Admin_Root) || GetAdminFlag(h_idAdmin, Admin_Kick)) {
		granted = true;
	}
	else {
		ReplyToCommand( client, "[DELET]: Admin command only!" );
		granted = false;
	}
	return granted;
}

