#include <sourcemod>
#include <sdktools>
static pressedE[33];
static Float:lastpressedE[33];
static bool:PrethinkBuffer[33] = false;
static MaxPlayers;

public Plugin:myinfo =
{
	name = "E Spammer",
	author = "Krim",
	description = "Blocks Spamming E",
	version = "1.1.0.0",
	url = ""
};

//Initation:
public OnPluginStart()
{
    MaxPlayers = GetMaxClients();
}
 
//THX to SAMURAI16 for this code
stock SetClientButtons(client,buttons)
{
    return SetEntProp(client, Prop_Data, "m_nButtons",buttons);
}
//THX

public OnGameFrame()
{
	//Loop:
	for(new Client = 1; Client <= MaxPlayers; Client++)
	{
		//Connected:
		if(IsClientConnected(Client) && IsClientInGame(Client) && IsPlayerAlive(Client))
		{
			if(GetClientButtons(Client) & IN_USE)
	        	{
                		if(!PrethinkBuffer[Client])    
                		{
                    			PrethinkBuffer[Client] = true; 
                    			decl Ent;
                    			decl String:ClassName[20];
                    			Ent = GetClientAimTarget(Client, false);
                    
                    			if(IsValidEntity(Ent) && Ent > MaxPlayers)
                    			{
                        			GetEdictClassname(Ent, ClassName, 20);
                        			if(StrEqual(ClassName, "func_door_rotating") || StrEqual(ClassName, "prop_door_rotating"))
                        			{    
                            				decl Float:ClientOrigin[3], Float:EntOrigin[3];  
                            				decl Float:Dist;
                            				GetClientAbsOrigin(Client, ClientOrigin);
                            				GetEntPropVector(Ent, Prop_Send, "m_vecOrigin", EntOrigin);
                            				Dist = GetVectorDistance(ClientOrigin, EntOrigin);
                            
                            				if(Dist < 300)
                            				{
                                				if(!pressedE[Client]) pressedE[Client] = 1;
                                				else pressedE[Client]++;
                                 
                                				if(lastpressedE[Client] >= GetGameTime()-3)
                                				{     
                                    					if(pressedE[Client] > 3)
                                                                {
                                                                PrintToChat(Client, "[DoorBlock] Stop DoorBlocking");
                                                                } 
                                				} else
                                				{
                                     					pressedE[Client] = 1;
                                				}
                                				lastpressedE[Client] = GetGameTime();
                            				}			
                       				}
                    			}
                		}
                        
                        if(lastpressedE[Client] >= GetGameTime()-3)
                        {     
                            if(pressedE[Client] > 3)
                            {
                            new buttons = GetClientButtons(Client);
                            buttons &= ~IN_USE;
                            SetClientButtons(Client,buttons); 
                            } 
                        }
	        	}
            		else
            		{
            			//Hook:
            			PrethinkBuffer[Client] = false;
            		}
        	} 
    	}
}