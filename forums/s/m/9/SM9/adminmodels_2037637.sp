#define MODELS_PER_TEAM 8
#define MAX_FILE_LEN 256

#include <sourcemod>
#include <sdktools>

new String:g_Models_Admin[MODELS_PER_TEAM][MAX_FILE_LEN];
new String:g_Models_Count_Admin;

public Plugin:myinfo = 
{
	name = "Admin Skins",
	author = "",
	description = "",
	version = "1.0",
	url = ""
}

public OnPluginStart()
	HookEvent("player_spawn", Event_PlayerSpawn);

public OnMapStart()
{
	g_Models_Count_Admin = 0;
	
	LoadModels(g_Models_Admin,  "configs/adminmodels.ini");
	
	g_Models_Count_Admin  = LoadModels(g_Models_Admin,  "configs/adminmodels.ini");
}

public Action:Event_PlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(Client_IsValid(client)){
		set_models(client);
	}
}

stock set_models(client_index){
	if(Client_IsValid(client_index) && GetUserAdmin(client_index) != INVALID_ADMIN_ID){
		SetEntityModel(client_index,g_Models_Admin[GetRandomInt(0, g_Models_Count_Admin-1)]);
	}
}

stock LoadModels(String:models[][], String:ini_file[]){
	decl String:buffer[MAX_FILE_LEN];
	decl String:file[MAX_FILE_LEN];
	new models_count;
	
	BuildPath(Path_SM, file, MAX_FILE_LEN, ini_file);
	
	new Handle:fileh = OpenFile(file, "r");
	while (ReadFileLine(fileh, buffer, MAX_FILE_LEN)){
		TrimString(buffer);
		
		if (FileExists(buffer)){
			AddFileToDownloadsTable(buffer);
			if (StrEqual(buffer[strlen(buffer)-4], ".mdl", false) && (models_count<MODELS_PER_TEAM)){
				strcopy(models[models_count++], strlen(buffer)+1, buffer);
				PrecacheModel(buffer, true);
			}
		}
	}
	return models_count;
}

stock bool:Client_IsValid(client, bool:checkConnected=true)
{
	if (client > 4096) {
		client = EntRefToEntIndex(client);
	}
	
	if (client < 1 || client > MaxClients) {
		return false;
	}
	
	if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) )
		return false; 
	
	
	if (checkConnected && !IsClientConnected(client)) {
		return false;
	}
	
	return true;
}