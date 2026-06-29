//Gun Enablers
bool HeHadThisWeapon[MAXPLAYERS + 1];


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
        if(IsClientInGame(player)){

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
			
			
			if(StrEqual(clsname, "weapon_goldenak47"))
			{
			    HeHadThisWeapon[player] = true;
            }

           //████████╗██╗░░██╗██╗░░██╗  ██████╗░░█████╗░░█████╗░░█████╗░██████╗░██████╗░██╗
           //╚══██╔══╝██║░░██║╚██╗██╔╝  ██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗██║
           //░░░██║░░░███████║░╚███╔╝░  ██████╦╝███████║██║░░╚═╝███████║██████╔╝██║░░██║██║
           //░░░██║░░░██╔══██║░██╔██╗░  ██╔══██╗██╔══██║██║░░██╗██╔══██║██╔══██╗██║░░██║██║
           //░░░██║░░░██║░░██║██╔╝╚██╗  ██████╦╝██║░░██║╚█████╔╝██║░░██║██║░░██║██████╔╝██║
           //░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝  ╚═════╝░╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝╚═╝░░╚═╝╚═════╝░╚═╝
        }
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
	    if(HeHadThisWeapon[client])
		{
		/////////////////////////Using timer to give guns based of SLOTS to reduce server lag
	    CreateTimer(0.3, GiveHisGunBack, client);
		}
	}
}




//█▀▀ █░█ █▄░█ █▀▀ ▀█▀ █ █▀█ █▄░█ █▀
//█▀░ █▄█ █░▀█ █▄▄ ░█░ █ █▄█ █░▀█ ▄█
public OnClientPutInServer(client)
{
		 HeHadThisWeapon[client] = false;
}
/////////////////////
///////////////////// Give the old man his guns back
/////////////////////
public Action GiveHisGunBack(Handle:timer)
{
    for (new i = 1; i <= MaxClients; i++) 
	{
	  if(HeHadThisWeapon[i])
		{
	      FakeClientCommand(i, "sm_goldenak47");
		  HeHadThisWeapon[i] = false;
		}
	}
    return;
}