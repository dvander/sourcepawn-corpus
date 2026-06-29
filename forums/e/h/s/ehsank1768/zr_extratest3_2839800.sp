//Gun Enablers
bool HKVIP[MAXPLAYERS + 1];
bool INFINITYSLINGER[MAXPLAYERS + 1];
bool DUALDEAGLE[MAXPLAYERS + 1];
bool AK47BLOODLUST[MAXPLAYERS + 1];
bool BALROG5[MAXPLAYERS + 1];
bool SCARVIP[MAXPLAYERS + 1];
bool MINIGUN[MAXPLAYERS + 1];
bool THUNDERBOLT[MAXPLAYERS + 1];
bool AWPBUFF[MAXPLAYERS + 1];
bool AT15HW[MAXPLAYERS + 1];
bool BALROG1[MAXPLAYERS + 1];
bool SAIPENTA[MAXPLAYERS + 1];
bool ANACONDA[MAXPLAYERS + 1];
bool M16NEW[MAXPLAYERS + 1];
bool XM2010[MAXPLAYERS + 1];
bool INFINITYG[MAXPLAYERS + 1];
bool KNIFEW[MAXPLAYERS + 1];
bool ADMINKNIFE[MAXPLAYERS + 1];
bool KATANA[MAXPLAYERS + 1];
bool RPGB[MAXPLAYERS + 1];
bool RPGCN[MAXPLAYERS + 1];
bool NEMESIS[MAXPLAYERS + 1];
bool LILITH[MAXPLAYERS + 1];
bool HOSTBIG[MAXPLAYERS + 1];
bool HOST[MAXPLAYERS + 1];
bool INFECTIONBOMB[MAXPLAYERS + 1];
bool FROGBOMB[MAXPLAYERS + 1];
bool DEIMOSBOMB[MAXPLAYERS + 1];
bool DRUGBOMB[MAXPLAYERS + 1];
bool JUMP[MAXPLAYERS + 1];
bool PROPDAMAGE[MAXPLAYERS + 1];
bool KNIFEBUTTERFLY[MAXPLAYERS + 1];
bool KNIFEJETT[MAXPLAYERS + 1];
bool KNIFEMAGEPUNK[MAXPLAYERS + 1];
bool KNIFEAJAX[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "Extra Item Bugfix",
	author = "Bacardi",
	description = "",
	version = "1.0",
	url = ""
};
public OnPluginStart()
{
    HookEvent("round_start", RoundStart, EventHookMode_Post);
	HookEvent("round_end", RoundEnd, EventHookMode_PostNoCopy);
}

public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{

        CreateTimer(3.0, test);

}

public Action test(Handle:timer, int args)
{
    int array_size;
    int entity;
    int ammotype;
    char clsname[] = "weapon_smokegrenadeeeeeee";

    clsname[0] = '\0';

    for(int player = 1; player <= MaxClients; player++)
    {
        if(!IsClientInGame(player) || !IsPlayerAlive(player)) continue;

        PrintToServer("\nPerson %N is carrying:", player);

        if(GetEntProp(player, Prop_Send, "m_bHasDefuser"))
            PrintToServer("- pocket slot -1: Defuser");

        if(GetEntProp(player, Prop_Send, "m_bHasNightVision"))
            PrintToServer("- pocket slot -1: NightVision");


        array_size = GetEntPropArraySize(player, Prop_Send, "m_hMyWeapons");
        
        for(int pocket = 0; pocket < array_size; pocket++)
        {
            entity = GetEntPropEnt(player, Prop_Send, "m_hMyWeapons", pocket);

            if(entity == -1) continue;
            
            GetEntityClassname(entity, clsname, sizeof(clsname));
			
			
			

           //░█████╗░██████╗░██████╗░  ░██╗░░░░░░░██╗███████╗░█████╗░██████╗░░█████╗░███╗░░██╗  ██╗░░██╗███████╗██████╗░███████╗
           //██╔══██╗██╔══██╗██╔══██╗  ░██║░░██╗░░██║██╔════╝██╔══██╗██╔══██╗██╔══██╗████╗░██║  ██║░░██║██╔════╝██╔══██╗██╔════╝
           //███████║██║░░██║██║░░██║  ░╚██╗████╗██╔╝█████╗░░███████║██████╔╝██║░░██║██╔██╗██║  ███████║█████╗░░██████╔╝█████╗░░
           //██╔══██║██║░░██║██║░░██║  ░░████╔═████║░██╔══╝░░██╔══██║██╔═══╝░██║░░██║██║╚████║  ██╔══██║██╔══╝░░██╔══██╗██╔══╝░░
           //██║░░██║██████╔╝██████╔╝  ░░╚██╔╝░╚██╔╝░███████╗██║░░██║██║░░░░░╚█████╔╝██║░╚███║  ██║░░██║███████╗██║░░██║███████╗
           //╚═╝░░╚═╝╚═════╝░╚═════╝░  ░░░╚═╝░░░╚═╝░░╚══════╝╚═╝░░╚═╝╚═╝░░░░░░╚════╝░╚═╝░░╚══╝  ╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚══════╝
			
			
			if(StrEqual(clsname, "weapon_anaconda"))
			{
			    ANACONDA[player] = true;
            }
			if(StrEqual(clsname, "weapon_glock"))
			{
			    PrintToChat(player, "testme");
            }

           //████████╗██╗░░██╗██╗░░██╗  ██████╗░░█████╗░░█████╗░░█████╗░██████╗░██████╗░██╗
           //╚══██╔══╝██║░░██║╚██╗██╔╝  ██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗██║
           //░░░██║░░░███████║░╚███╔╝░  ██████╦╝███████║██║░░╚═╝███████║██████╔╝██║░░██║██║
           //░░░██║░░░██╔══██║░██╔██╗░  ██╔══██╗██╔══██║██║░░██╗██╔══██║██╔══██╗██║░░██║██║
           //░░░██║░░░██║░░██║██╔╝╚██╗  ██████╦╝██║░░██║╚█████╔╝██║░░██║██║░░██║██████╔╝██║
           //░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝  ╚═════╝░╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝╚═╝░░╚═╝╚═════╝░╚═╝
        }
		}

    return Plugin_Handled;
} 
/////////////////////
///////////////////// Have a heart we gotta helpless old man with us
/////////////////////
public RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    for (new client = 1; client <= MaxClients; client++) 
	{
	    if(ANACONDA[client])
		{
		PrintToChatAll("Worked");
		/////////////////////////Using timer to give guns based of SLOTS to reduce server lag
	    CreateTimer(1.0, Anaconda, client);
		}
	}
}




//█▀▀ █░█ █▄░█ █▀▀ ▀█▀ █ █▀█ █▄░█ █▀
//█▀░ █▄█ █░▀█ █▄▄ ░█░ █ █▄█ █░▀█ ▄█
public OnClientPutInServer(client)
{
		 HKVIP[client] = false;
		 INFINITYSLINGER[client] = false;
		 DUALDEAGLE[client] = false;
		 AK47BLOODLUST[client] = false;
		 BALROG5[client] = false;
		 SCARVIP[client] = false;
		 MINIGUN[client] = false;
		 THUNDERBOLT[client] = false;
		 AWPBUFF[client] = false;
		 AT15HW[client] = false;
		 BALROG1[client] = false;
		 SAIPENTA[client] = false;
		 ANACONDA[client] = false;
		 M16NEW[client] = false;
		 XM2010[client] = false;
		 INFINITYG[client] = false;
		 KNIFEW[client] = false;
		 ADMINKNIFE[client] = false;
		 KATANA[client] = false;
		 RPGB[client] = false;
		 RPGCN[client] = false;
		 NEMESIS[client] = false;
		 LILITH[client] = false;
		 HOSTBIG[client] = false;
		 HOST[client] = false;
		 INFECTIONBOMB[client] = false;
		 FROGBOMB[client] = false;
		 DEIMOSBOMB[client] = false;
		 DRUGBOMB[client] = false;
		 JUMP[client] = false;
		 PROPDAMAGE[client] = false;
		 KNIFEBUTTERFLY[client] = false;
		 KNIFEJETT[client] = false;
		 KNIFEMAGEPUNK[client] = false;
		 KNIFEAJAX[client] = false;
}
public OnClientDisconnect(client)
{
		 HKVIP[client] = false;
		 INFINITYSLINGER[client] = false;
		 DUALDEAGLE[client] = false;
		 AK47BLOODLUST[client] = false;
		 BALROG5[client] = false;
		 SCARVIP[client] = false;
		 MINIGUN[client] = false;
		 THUNDERBOLT[client] = false;
		 AWPBUFF[client] = false;
		 AT15HW[client] = false;
		 BALROG1[client] = false;
		 SAIPENTA[client] = false;
		 ANACONDA[client] = false;
		 M16NEW[client] = false;
		 XM2010[client] = false;
		 INFINITYG[client] = false;
		 KNIFEW[client] = false;
		 ADMINKNIFE[client] = false;
		 KATANA[client] = false;
		 RPGB[client] = false;
		 RPGCN[client] = false;
		 NEMESIS[client] = false;
		 LILITH[client] = false;
		 HOSTBIG[client] = false;
		 HOST[client] = false;
		 INFECTIONBOMB[client] = false;
		 FROGBOMB[client] = false;
		 DEIMOSBOMB[client] = false;
		 DRUGBOMB[client] = false;
		 JUMP[client] = false;
		 PROPDAMAGE[client] = false;
		 KNIFEBUTTERFLY[client] = false;
		 KNIFEJETT[client] = false;
		 KNIFEMAGEPUNK[client] = false;
		 KNIFEAJAX[client] = false;
}
/////////////////////
///////////////////// Give the old man his guns back
///////////////////// PISTOLS
public Action Anaconda(Handle:timer)
{
    for (new i = 1; i <= MaxClients; i++) 
	{
	  if(ANACONDA[i])
		{
	      FakeClientCommand(i, "sm_anaconda");
		  ANACONDA[i] = false;
		}
	}
    return;
}
/////////////////////
///////////////////// PRIMARY
/////////////////////

/////////////////////
///////////////////// MELEE
/////////////////////

/////////////////////
///////////////////// HEGRENADE SLOT
/////////////////////

/////////////////////
///////////////////// SMOKE SLOT
/////////////////////

/////////////////////
///////////////////// FLASH SLOT
/////////////////////

/////////////////////
///////////////////// C4 SLOT??
/////////////////////