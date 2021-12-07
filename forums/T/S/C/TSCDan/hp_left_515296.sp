#include <sourcemod>

//0=attacker name, 1=attacker weapon
new String:deathInfo[MAXPLAYERS+1][2][32];
new hpleft[MAXPLAYERS+1];
new dmgTaken[MAXPLAYERS+1][MAXPLAYERS+1];
new dmgGiven[MAXPLAYERS+1][MAXPLAYERS+1];
new hitsTaken[MAXPLAYERS+1][MAXPLAYERS+1];
new hitsGiven[MAXPLAYERS+1][MAXPLAYERS+1];
//0=didn't kill, 1=normal, 2=HS
new kills[MAXPLAYERS+1][MAXPLAYERS+1];
new distances[MAXPLAYERS+1];
new bool:headshots[MAXPLAYERS+1];
new bool:display[MAXPLAYERS+1];
new Handle:hpl_time;
new Handle:hpl_chat;
new Handle:hpl_color;
new Handle:hpl_verbose;
new String:color[5];

#define PLUGIN_VERSION "1.5"

public Plugin:myinfo = {
	name = "HP left",
	author = "vIr-Dan",
	description = "Shows how many hp an attacker has left",
	version = PLUGIN_VERSION,
	url = "http://dansbasement.us/"
};

public OnPluginStart()
{
	HookEvent("player_death", playerDeath)
	
	CreateConVar("sm_hpl_version", PLUGIN_VERSION, "HP left version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	hpl_time = CreateConVar("sm_hpl_time", "0", "How long to display hp left panel for in seconds (0 disabled)")
	hpl_chat = CreateConVar("sm_hpl_chat", "1", "Display hp left text in chat (0 off)")
	hpl_color = CreateConVar("sm_hpl_color", "1", "Color of chat text (0=yellow, 1=green)")
	hpl_verbose = CreateConVar("sm_hpl_verbose", "1", "Verbose listing of death statistics (1=on)");
	RegConsoleCmd("say", printInfoChat);
	RegConsoleCmd("say_team", printInfoChat);
	HookEvent("player_hurt",  playerHurt);
	
}

public OnConfigsExecuted(){
	if(GetConVarInt(hpl_color)==1){
		color="\x04";
	}
}

public Action:playerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(hpl_verbose)==1){
		//	"dmg_health"    "byte"  		// damage done to health
		//	"userid"        "short"         // player index who was hurt
		//	"attacker"      "short"         // player index who attacked
		new attacker  = GetClientOfUserId(GetEventInt(event, "attacker"));
		new victim	  = GetClientOfUserId(GetEventInt(event, "userid"));
		new damage    = GetEventInt(event, "dmg_health");
		
		dmgTaken[victim][attacker] += damage;
		dmgGiven[attacker][victim] += damage;
		hitsTaken[victim][attacker]++;
		hitsGiven[attacker][victim]++;
	}
	
	return Plugin_Continue
}

public OnClientPutInServer(client){
	display[client]=true
	CreateTimer(5.0,joinMsg,client)
}

public Action:joinMsg(Handle:timer,any:client){
	if (client && IsClientInGame(client))
	{
		PrintToChat(client,"%s[HP] Say hp to toggle hp left on/off",color)
	}
}

public Action:printInfoChat(client, args){
	//Make sure it's not console
	if(client == 0){
		return Plugin_Continue
	}
	
	//Get the user's command
	new String:user_command[192];
	GetCmdArgString(user_command, 192);
	ReplaceString(user_command, 192, "\"", "")
	TrimString(user_command)
	if(strcmp("hp",user_command,false) ==0){
		if(display[client]){
			display[client]=false
			PrintToChat(client,"%sHP left turned off",color)
		}else{
			display[client]=false
			PrintToChat(client,"%sHP left turned on",color)
		}
	}
	
	return Plugin_Continue
}

public printInfo(client){
	if(GetConVarInt(hpl_verbose)==1){
		for(new i=0;i<sizeof(dmgTaken[]);i++){
			if(dmgTaken[client][i] > 0){
				new String:attackerName[32];
				if(IsClientConnected(i) && !GetClientName(i,attackerName,32)){
					attackerName = "DISCONNECTED";
				}
				PrintToChat(client,"%sATTACKER %s » %i dmg, %i hits",color, attackerName, dmgTaken[client][i], hitsTaken[client][i]) 
			}
		}
		for(new i=0;i<sizeof(dmgGiven[]);i++){
			if(dmgGiven[client][i] > 0){
				new String:victimName[32];
				if(IsClientConnected(i) && !GetClientName(i,victimName,32)){
					victimName = "DISCONNECTED";
				}
				if(kills[client][i]>0){
					new String:hs[6];
					if(kills[client][i]==2){
						hs=" (HS)";
					}
					PrintToChat(client,"%sKILLED%s %s » %i dmg, %i hits",color, hs, victimName, dmgGiven[client][i], hitsGiven[client][i]) 
				}else{
					PrintToChat(client,"%sHURT %s » %i dmg, %i hits",color, victimName, dmgGiven[client][i], hitsGiven[client][i]) 
				}
			}
		}
	}
	
	if(headshots[client]){	
		PrintToChat(client,"%s%s killed you with %s (HS) from %i feet and has %i hp left",color,deathInfo[client][0],deathInfo[client][1],distances[client],hpleft[client])
	}else{
		PrintToChat(client,"%s%s killed you with %s from %i feet and has %i hp left",color,deathInfo[client][0],deathInfo[client][1],distances[client],hpleft[client])
	}
	
}


public Action:playerDeath(Handle:event, const String:name[], bool:dontBroadcast){
	new bool:headshot = GetEventBool(event, "headshot")
	new victim = GetClientOfUserId(GetEventInt(event, "userid"))
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
	
	//Suicide of some form, not paying attention
	if(attacker == victim){
		return Plugin_Continue
	}
	
	if(headshot){
		kills[attacker][victim]=2;
	}else{
		kills[attacker][victim]=1;
	}
	
	new String:attackerName[32]
	if(IsClientConnected(attacker) && !GetClientName(attacker,attackerName,32)){
		attackerName= "DISCONNECTED";
	}
	new String:weapon[32]
	GetEventString(event, "weapon", weapon, 32)
	ReplaceString(weapon, 32, "WEAPON_", "")
	
	//Get the distance
	new Float:victimLoc[3];
	new Float:attackerLoc[3];
	GetClientAbsOrigin(victim,victimLoc)
	GetClientAbsOrigin(attacker,attackerLoc)
	new distance = RoundToNearest(FloatDiv(calcDistance(victimLoc[0],attackerLoc[0], victimLoc[1],attackerLoc[1], victimLoc[2],attackerLoc[2]),12.0))
	
	//Store the info in the arrays
	strcopy(deathInfo[victim][0],sizeof(deathInfo[][]),attackerName)
	strcopy(deathInfo[victim][1],sizeof(deathInfo[][]),weapon)
	hpleft[victim] = GetClientHealth(attacker)
	distances[victim] = distance
	headshots[victim] = headshot
	
	if(display[victim]){
		if(GetConVarInt(hpl_chat)==1){
			printInfo(victim)
		}
		if(GetConVarInt(hpl_time) > 0){
			printInfoPanel(victim)
		}
	}
	
	if(GetConVarInt(hpl_verbose)==1){
		for(new i;i<sizeof(dmgTaken[]);i++){
			dmgTaken[victim][i]=0;
			dmgGiven[victim][i]=0;
			hitsTaken[victim][i]=0;
			hitsGiven[victim][i]=0;
		}
	}
	
	return Plugin_Continue
}

public Float:calcDistance(Float:x1,Float:x2,Float:y1,Float:y2,Float:z1,Float:z2){ 
	//Distance between two 3d points
	new Float:dx = x1-x2 
	new Float:dy = y1-y2 
	new Float:dz = z1-z2 

	return(SquareRoot(dx*dx + dy*dy + dz*dz))
}


//Thanks to ferret for the panel code
stock printInfoPanel(client)
{
	decl String:title[100];
	Format(title, 64, "Attacker: %s:", deathInfo[client][0]);
	
	decl String:headshotText[3];
	if(headshots[client]){
		headshotText = "Yes"
	}else{
		headshotText= "No"
	}
	decl String:message[128]
	Format(message, 128, "HP Left: %i\nWeapon: %s\nDistance: %i\nHeadshot: %s\n", hpleft[client], deathInfo[client][1], distances[client], headshotText)
	
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, title);
	DrawPanelItem(panel, "", ITEMDRAW_SPACER);
	DrawPanelText(panel, message);
	DrawPanelItem(panel, "", ITEMDRAW_SPACER);

	SetPanelCurrentKey(panel, 10);
	DrawPanelItem(panel, "Exit", ITEMDRAW_CONTROL);

	SendPanelToClient(panel, client, Handler_DoNothing, GetConVarInt(hpl_time));

	CloseHandle(panel);
}

public Handler_DoNothing(Handle:menu, MenuAction:action, param1, param2)
{
	/* PAR-TAY!!! >.> */
}