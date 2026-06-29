#include <sourcemod>
#include <l4d2_InfectedSpawnApi>

#if InfectedApiVersion1_6
#else
#error Plugin required Infected Api Version 1.6
#endif

public Plugin:myinfo = 
{
	name = "[L4D2] Sample InfectedAPI Plugin",
	author = "V10",
	description = "Sample use InfectedAPI",
	version = "1.0",
	url = ""
}

public OnPluginStart()
{	
	InitInfectedSpawnAPI();
	RegAdminCmd("sm_spawnz", Command_spawnz, ADMFLAG_SLAY);
}

public Action:Command_spawnz(client, args) {
	if (args<1) {
		ReplyToCommand(client,"Using sm_spawnz <zombieid> <ghost> <auto>");
		ReplyToCommand(client,"zombieid is zombie class:");
		for (new i = ZC_SMOKER; i <= ZC_TANK; i++){
			ReplyToCommand(client,"  - %d = %s",i,g_sBossNames[i]);
		}
		ReplyToCommand(client,"ghost: 1 = spawn ghost, 0 - spawn alived");
		ReplyToCommand(client,"auto: 1 =  set position by diresctor, 0 - use viewangles");
		return;
	}
	new String:tempStr[20];
	GetCmdArg(1,tempStr,20);
	new zombieId=StringToInt(tempStr);
	if (zombieId<ZC_SMOKER || zombieId>ZC_TANK){
		ReplyToCommand(client,"ERROR: Bad zombieId!");		
		return;
	}
	GetCmdArg(2,tempStr,20);
	new bool:fGhost=StringToInt(tempStr)>0;
	GetCmdArg(3,tempStr,20);
	new bool:fAuto=StringToInt(tempStr)>0;
	ReplyToCommand(client,"Spawning zombieId=%d, ghost=%d, auto=%d",zombieId,fGhost,fAuto);
	SpawnInfectedBoss(client,zombieId,fGhost,fAuto,fGhost);
}
