#include <sourcemod>
#include <sdktools>
//Buguse
static pressedE[33];
static Float:lastpressedE[33];
static bool:PrethinkBuffer[33] = false;

public Plugin:myinfo =
{
	name = "E Spammer",
	author = "Krim",
	description = "Blocks Spamming E",
	version = "1.0.0.0",
	url = ""
};
 
public OnGameFrame()
{
	//Declare:
	decl MaxPlayers;

	//Initialize:
	MaxPlayers = GetMaxClients();

	//Loop:
	for(new Client = 1; Client <= MaxPlayers; Client++)
	{
		//Connected:
		if(IsClientConnected(Client) && IsClientInGame(Client))
		{
			if(GetClientButtons(Client) & IN_USE)
	        	{
                		if(!PrethinkBuffer[Client])    
                		{
                    			PrethinkBuffer[Client] = true; 
                    			decl Ent;
                    			decl String:ClassName[255];
                      
                    			Ent = GetClientAimTarget(Client, false);
                    
                    			if(Ent != -1 && Ent > 0 && Ent > GetMaxClients())
                    			{
                        			GetEdictClassname(Ent, ClassName, 255);
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
                                    					if(pressedE[Client] == 15)
                                    					{
                                        					PrintToChat(Client,"[DoorBlock] You'll be killed in 10 seconds..."); 
                                        					IgniteEntity(Client, 10.0);  
                                        					CreateTimer(10.0, Suicide, Client);
                                    					}
                                    					else if(pressedE[Client] == 14)
                                        					PrintToChat(Client, "[DoorBlock] LAST WARNING: Stop Doorblocking or SLAY!");  
                                    					else if(pressedE[Client] == 10)
                                        					PrintToChat(Client, "[DoorBlock] Warning: Stop Doorblocking or SLAY!"); 
                                    					else if(pressedE[Client] == 8)
                                        					PrintToChat(Client, "[DoorBlock] Stop DoorBlocking!"); 
                                    					else if(pressedE[Client] == 4)
                                        					PrintToChat(Client, "[DoorBlock] Stop DoorBlocking"); 
                                				} else
                                				{
                                     					pressedE[Client] = 1;
                                				}
                                				lastpressedE[Client] = GetGameTime();
                            				}			
                       				}
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

public Action:Suicide(Handle:Timer, any:Client)
{
    ForcePlayerSuicide(Client);
    return Plugin_Handled; 
}
 