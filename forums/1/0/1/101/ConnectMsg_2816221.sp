#include <geoip>
#include <sdktools_sound>

char IP[16],Country[32];

public OnClientPutInServer(P)
{
	if(!IsFakeClient(P))	Send(P,"joined","buttons/bell1.wav");
}

public OnClientDisconnect(P)	
{
	if(!IsFakeClient(P))	Send(P,"left","buttons/blip2.wav");
}

Send(int P, char[] Status , char[] C_Sound)
{	
	GetClientIP(P,IP,16);
	
	if(GeoipCountry(IP,Country,32))
	{
		for(int i=1;i<=MaxClients;i++)
		{
			if(!IsClientInGame(i))	continue;
			
			PrintToChat(i,"\x04%N \x01 has %s the game \x05[%s]",P,Status,Country);
			
			EmitSoundToClient(i,C_Sound);
		}
	}
}