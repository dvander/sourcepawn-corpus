#pragma semicolon 1

#include <sourcemod>
#include <menus>
#include <tf2items>
#include <sdktools>
#include <sdkhooks>
#include <tf2idb>
#include <clientprefs>


#define MAXONE MAXPLAYERS+1
#define MESSAGE "You must die or change class for changes to take effect."

new const String:sMenuItems[][] = {
 
    {"6|Green Confetti"},
    {"7|Purple Confetti"},
    {"8|Haunted Ghosts"},
    {"9|Green Energy"},
    {"10|Purple Energy"},
    {"11|Circling TF Logo"},
    {"12|Massed Flies"},
    {"13|Burning Flames"},
    {"14|Scorching Flames"},
    {"15|Searing Plasma"},
    {"16|Vivid Plasma"},
    {"17|Sunbeams"},
    {"18|Circling Peace Sign"},
    {"19|Circling Heart"},
    {"29|Stormy Storm"},
    {"30|Blizzardy Storm"},
    {"31|Nuts n' Bolts"},
    {"32|Orbiting Planets"},
    {"33|Orbiting Fire"},
    {"34|Bubbling"},
    {"35|Smoking"},
    {"36|Steaming"},
    {"37|Flaming Lantern"},
    {"38|Cloudy Moon"},
    {"39|Cauldron Bubbles"},
    {"40|Eerie Orbiting Fire"},
    {"43|Knifestorm"},
    {"44|Misty Skull"},
    {"45|Harvest Moon"},
    {"46|It's A Secret To Everybody"},
    {"47|Stormy 13th Hour"},
    {"56|Kill-a-Watt"},
    {"57|Terror-Watt"},
    {"58|Cloud 9"},
    {"59|Aces High"},
    {"60|Dead Presidents"},
    {"61|Miami Nights"},
    {"62|Disco Beat Down"},
    {"63|Phosphorous"},
    {"64|Sulphurous"},
    {"65|Memory Leak"},
    {"66|Overclocked"},
    {"67|Electrostatic"},
    {"68|Power Surge"},
    {"69|Anti-Freeze"},
    {"70|Time Warp"},
    {"71|Green Black Hole"},
    {"72|Roboactive"},
    {"73|Arcana"},
    {"74|Spellbound"},
    {"75|Chiroptera Venenata"},
    {"76|Poisoned Shadows"},
    {"77|Something Burning This Way Comes"},
    {"78|Hellfire"},
    {"79|Darkblaze"},
    {"80|Demonflame"},
    {"81|Bonzo The All-Gnawing"},
    {"82|Amaranthine"},
    {"83|Stare From Beyond"},
    {"84|The Ooze"},
    {"85|Ghastly Ghosts Jr"},
    {"86|Haunted Phantasm Jr"},
    {"87|Frostbite"},
    {"88|Motlen Mallard"},
    {"89|Morning Glory"},
    {"90|Death At Dusk"},
    {"91|Abduction"},
    {"92|Atomic"},
    {"93|Subatomic"},
    {"94|Electric Hat Protector"},
    {"95|Magnetic Hat Protector"},
    {"96|Voltaic Hat Protector"},
    {"97|Galactic Codex"},
    {"98|Ancient Codex"},
    {"99|Nebula"},
    {"100|Death By Disco"},
    {"101|It's a mystery to everyone"},
    {"102|It's a puzzle to me"},
    {"103|Ether Trail"},
    {"104|Nether Trail"},
    {"105|Ancient Eldritch"},
    {"106|Eldritch Flame"}
 
};


new Handle:hUnusualMenu = INVALID_HANDLE;

new Float:fEffects[MAXONE]		= {0.0, ...};
new Handle:hNextItem[MAXONE]	= {INVALID_HANDLE, ...};
new bool:bItemWaiting[MAXONE]	= {false, ...};
new bool:firstSpawn[MAXONE] =  { false, ... };
new Handle:cEffects;

public Plugin:myinfo =
{
	name = "[TF2] Unusuals",
	author = "Kuroiwa",
	description = "Provides !unusuals command that allows players to equip unusual effects.",
	version = "1.0",
	url = "https://amahoukuroiwa.wordpress.com/"
};


public OnPluginStart(){
 
 	CreateConVar("sm_unusuals_version", "1.0", "Unusuals Plugin Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
 
	RegAdminCmd("sm_unusuals", Command_UnusualMenu, 0, "Displays the unusuals menu.");
	RegAdminCmd("sm_unusual", Command_UnusualMenu, 0, "Displays the unusuals menu.");
	RegAdminCmd("sm_effects", Command_UnusualMenu, 0, "Displays the unusuals menu.");
	RegAdminCmd("sm_effect", Command_UnusualMenu, 0, "Displays the unusuals menu.");
	
	cEffects = RegClientCookie("unusuals_cookie", "", CookieAccess_Private);
	
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Pre);
	
	hUnusualMenu = Menu_BuildMain();
	
	for (new i = 1; i <= MaxClients; i++)
	{
		fEffects[i] = 0.0;
		if(IsClientInGame(i) && AreClientCookiesCached(i)) OnClientCookiesCached(i);
	}
}

public Action:OnPlayerSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (firstSpawn[client] && fEffects[client] != 0.0)
	{
		AddEffect(client, fEffects[client]);
		firstSpawn[client] = false;
	}
}

public Action:Command_UnusualMenu(client, args){

	if(!IsValidClient(client)) return Plugin_Handled;

	DisplayMenu(hUnusualMenu, client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;

}

Handle:Menu_BuildMain(){

	new Handle:hMenu = CreateMenu(Menu_Manager);
	
	SetMenuTitle(hMenu, "Unusual Effects");
	
	AddMenuItem(hMenu, "0", "Remove Effect");
	AddMenuItem(hMenu, "X", "--------", 1);
	
	new String:sItemIDName[2][32];
	for(new i = 0; i < sizeof(sMenuItems); i++){
	
		ExplodeString(sMenuItems[i], "|", sItemIDName, sizeof(sItemIDName), sizeof(sItemIDName[]));
	
		AddMenuItem(hMenu, sItemIDName[0], sItemIDName[1]);
	
	}
	
	return hMenu;

}

public Menu_Manager(Handle:hMenu, MenuAction:state, client, position){
	
	if(!IsValidClient(client))	return 0;
	
	if(state == MenuAction_Select){
	
		new String:sItem[4]; GetMenuItem(hMenu, position, sItem, sizeof(sItem));
		SetClientCookie(client, cEffects, sItem);
				
		StringToFloat(sItem) == 0 ? RemoveEffect(client) : AddEffect(client, StringToFloat(sItem));
					
		DisplayMenuAtItem(hMenu, client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
	
	}

	return 1;

}

stock AddEffect(client, Float:effect_id){

	new iHat = GetPlayersHat(client);

	if(iHat < 1){

		PrintToChat(client, "[SM] You do not have a hat equipped!");
		return;

	}

	new Handle:hItem	= TF2Items_CreateItem(PRESERVE_ATTRIBUTES|OVERRIDE_ALL);

	TF2Items_SetClassname(hItem, "tf_wearable");
	TF2Items_SetItemIndex(hItem, iHat);
	TF2Items_SetNumAttributes(hItem, 1);
	TF2Items_SetAttribute(hItem, 0, 134, effect_id);

	fEffects[client]		= effect_id;
	bItemWaiting[client]	= true;
	hNextItem[client]		= CloneHandle(hItem);
	
	CloseHandle(hItem);
	
	new ent = -1;
	while((ent = FindEntityByClassname(ent, "tf_wearable")) != INVALID_ENT_REFERENCE){
	
		if(!IsValidEntity(ent)) continue;
		
		if(client == GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity"))
			AcceptEntityInput(ent, "Kill");
	
	}
	
	CreateTimer(0.05, Timer_Resupply_Post, client);

}

public Action:Timer_Resupply_Post(Handle:timer, any:client){

	new vClip[3], Float:vEngClip[3], caberDetonated, caberBroken, weapon;
	for(new i = 0; i < sizeof(vClip); i++){
		weapon = GetPlayerWeaponSlot(client, i);
		switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")){
			case 441,442,588:{
				vEngClip[i] = GetEntPropFloat(weapon, Prop_Send, "m_flEnergy");
			}
			
			case 307:{
				caberBroken = GetEntProp(weapon, Prop_Send, "m_bBroken");
				caberDetonated = GetEntProp(weapon, Prop_Send, "m_iDetonated");
			}
			
			default:{
				vClip[i] = GetEntProp(weapon, Prop_Data, "m_iClip1");
			}
		}
		
	}

	new Float:drink	= GetEntPropFloat(client, Prop_Send, "m_flEnergyDrinkMeter");
	new health		= GetEntProp(client, Prop_Send, "m_iHealth");
	new metal		= GetEntProp(client, Prop_Data, "m_iAmmo", 4, 3);
	new Float:cloak	= GetEntPropFloat(client, Prop_Send, "m_flCloakMeter");
	new cond		= GetEntProp(client, Prop_Send, "m_nPlayerCond");
	
	//
	
	TF2_RegeneratePlayer(client);
	
	//
	
	for(new i = 0; i < sizeof(vClip); i++){
		weapon = GetPlayerWeaponSlot(client, i);
		switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")){
			case 441,442,588:{
				SetEntPropFloat(weapon, Prop_Send, "m_flEnergy", vEngClip[i]);
			}
			
			case 307:{
				SetEntProp(weapon, Prop_Send, "m_bBroken", caberBroken);
				SetEntProp(weapon, Prop_Send, "m_iDetonated", caberDetonated);
			}
			
			default:{
				SetEntProp(weapon, Prop_Data, "m_iClip1", vClip[i]);
			}
		}
		
	}
	
	SetEntPropFloat(client, Prop_Send, "m_flEnergyDrinkMeter", drink);
	SetEntityHealth(client, health);
	SetEntProp(client, Prop_Data, "m_iAmmo", metal, 4, 3);
	SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", cloak);
	SetEntProp(client, Prop_Send, "m_nPlayerCond", cond);
	
	return Plugin_Stop;

}

stock RemoveEffect(client){

	fEffects[client]		= 0.0;
	bItemWaiting[client]	= false;
	if(hNextItem[client] != INVALID_HANDLE) hNextItem[client] = INVALID_HANDLE;
	
	//TF2_RegeneratePlayer(client);
	PrintToChat(client, "[SM] %s", MESSAGE);

}

public Action:TF2Items_OnGiveNamedItem(client, String:strClassName[], iItemDefinitionIndex, &Handle:hItemOverride){

	if(hNextItem[client] != INVALID_HANDLE){
	
		new cacheditemindex = TF2Items_GetItemIndex(hNextItem[client]);
		
		if(IsValidClient(client) && bItemWaiting[client] && iItemDefinitionIndex == cacheditemindex){
		
			hItemOverride = hNextItem[client];
			hNextItem[client] = INVALID_HANDLE;
			bItemWaiting[client] = false;
			return Plugin_Changed;
		
		}
	}

	return Plugin_Continue;

}

GetPlayersHat(client){

	new ent = -1, id;
	while((ent = FindEntityByClassname(ent, "tf_wearable")) != INVALID_ENT_REFERENCE){//m_ModelName
	
		if(!IsValidEntity(ent)) continue;
		
		if(client != GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity")) continue;
		
		id = GetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex");
		
		
		if(TF2IDB_GetItemSlot(id) == TF2ItemSlot_Head)
			return id;
	
	}
	
	return 0;

}

public OnClientAuthorized(client, const String:auth[]){

	fEffects[client] = 0.0;

}

public OnClientDisconnect(client)
{
	fEffects[client] = 0.0;
}

public OnClientCookiesCached(client)
{
	new String:value[11];
	GetClientCookie(client, cEffects, value, sizeof(value));
	if (CheckCommandAccess(client, "sm_unusuals", 0, false))
	{
		fEffects[client] = StringToFloat(value);
		firstSpawn[client] = true;
	}
}

stock bool:IsValidClient(client){

	if(client > 4096){
		client = EntRefToEntIndex(client);
	}

	if(client < 1 || client > MaxClients)				return false;

	if(!IsClientInGame(client))						return false;

	if(IsFakeClient(client))							return false;
	
	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))	return false;
	
	return true;

}