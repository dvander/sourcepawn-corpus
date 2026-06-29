#include <sourcemod>

#pragma semicolon 1
public Plugin:myinfo =
{
	name = "Zarezerwowane sloty",
	author = "Mleczan",
	description = "Rezerwuje sloty graczom",
	version = "1.0",
	url = "http://www.sect-of-death.yoyo.pl"
}

//Global Vars
//------------------------------------------------------------------------------
new Handle:kick_message;
new Handle:IDList;
new String:argF[65];
new String:xxa[65];
new integer:enableM;
new integer:tmpM;
new String:SteamID[65];
new String:IPadr[65];
new String:CSteam[65];
new String:InfoKeyM[65];
new Handle:CzyWywalacZjebow;
new Handle:CzasZyciaPajaca;
new Handle:SposobWyrzucania;
new integer:ClientDoWyjebania;
new Handle:TimerUsuwajacy = INVALID_HANDLE;
new Handle:IloscWidocznychGraczy;
new Handle:PassPhraze;

public OnPluginStart()
{
	RegAdminCmd("slot", slot_addReg, ADMFLAG_CUSTOM1, "slocik dla kogos");
	RegAdminCmd("slot_EnableS", Enable_Slots, ADMFLAG_CUSTOM1, "liczba sl");
	CzyWywalacZjebow = CreateConVar("slot_zwalniaj", "0", "Jak 1 wypierdala smieci zeby slot zawsze byl wolny");
	CzasZyciaPajaca = CreateConVar("slot_zwalniaj_po", "120", "Po ilu sekunadach ma usunac gracza nadmiarowego bez slota");
    SposobWyrzucania = CreateConVar("slot_zwalniaj_typ", "0", "Jak 1 najmniej fragow, 0 tego co najkroecej gra");
	kick_message = CreateConVar("slot_kick_mess", "Slot zarezerwowany dla Panow", "Informacja za co kick");
	IloscWidocznychGraczy = FindConVar("sv_visiblemaxplayers");
    PassPhraze = CreateConVar("slot_PassPhraze", "_elo", "Informacja Setinfo na ktora ustawia sie haslo");

	LoadAllIDs();
}

public OnPluginEnd()
{
    ClearArray(IDList);
    SetConVarInt(IloscWidocznychGraczy,-1);
}

public OnMapStart()
{
	ClearArray(IDList);
	LoadAllIDs();
}

public Action:slot_addReg(client, args)
{
	if (args < 1)
	{
		return Plugin_Handled;	
	}
	new String:szArg[65];
	GetCmdArg(1, szArg, sizeof(szArg));
	PushArrayString(IDList,szArg);
	return Plugin_Handled;	
}

public Action:Enable_Slots(client, args)
{
	if (args < 1)
	{
		return Plugin_Handled;	
	}
	
	GetCmdArg(1, argF, sizeof(argF));
	tmpM = StringToInt(argF);
	if(!tmpM)
	{
		SetConVarInt(IloscWidocznychGraczy,-1);
		enableM = 0;
		return Plugin_Handled;
	}
	else
	{
		SetConVarInt(IloscWidocznychGraczy,(GetMaxClients() - 1));
		enableM = 1;
		return Plugin_Handled;
	}
}


public OnClientPostAdminCheck(client)
{
	if(enableM)
	{
		if(SprawdzZioma(client))
		{
			PrintToChatAll("Ziom nadchodzi....");
		}

		if((GetClientCount(false)) == GetMaxClients())
		{
            if(SprawdzZioma(client))
            {
                  if(GetConVarInt(CzyWywalacZjebow))
                  {
                      WypierdolSmiecia();
                  }
                  return true;
            }
            else
            {
                  WykopCapa(client);
                  return false;
            }
		}
	}
	return true;
}

public Action:SprawdzZioma(client)
{
       GetClientName(client, SteamID, 64);
       GetClientIP(client, IPadr, 64);
       GetClientAuthString(client,CSteam,64);
       GetConVarString(PassPhraze,xxa,64);
       GetClientInfo(client,xxa,InfoKeyM,64);
       Format(argF,64,"%s;%s",SteamID,InfoKeyM);
       
       if((-1 != FindStringInArray(IDList, SteamID)) || (-1 != FindStringInArray(IDList, IPadr)) || (-1 != FindStringInArray(IDList, CSteam)) || (-1 != FindStringInArray(IDList, argF)) )
       {
           return true;
       }
       else
       {
           return false;
       }
}

public Action:WypierdolSmiecia()
{
        ClientDoWyjebania = 0;
     	for (tmpM = 1; tmpM < GetMaxClients(); tmpM++)
	    {
		    if (IsClientInGame(tmpM) && !SprawdzZioma(tmpM))
		    {
               if( ClientDoWyjebania == 0)
               {
                   ClientDoWyjebania = tmpM;
               }
               if(!GetConVarInt(SposobWyrzucania))
               {
                  if(GetClientTime(ClientDoWyjebania) > GetClientTime(tmpM))
                  {
                      ClientDoWyjebania = tmpM;                      
                  }
               }
               else
               {
                  if((GetClientFrags(ClientDoWyjebania) > GetClientFrags(tmpM)) || ( (GetClientFrags(ClientDoWyjebania) == GetClientFrags(tmpM)) && (GetClientDeaths(ClientDoWyjebania) < GetClientDeaths(tmpM))) || ((GetClientFrags(ClientDoWyjebania)==GetClientFrags(tmpM))&& (GetClientDeaths(ClientDoWyjebania)==GetClientDeaths(tmpM)) && (GetClientTime(ClientDoWyjebania) > GetClientTime(tmpM))))
                  {
                      ClientDoWyjebania = tmpM;                      
                  }
               }
		    }
        }
        if(ClientDoWyjebania)
        {
               if(TimerUsuwajacy == INVALID_HANDLE)        
               {
                   TimerUsuwajacy = CreateTimer(GetConVarFloat(CzasZyciaPajaca), PoCzasieWyjeb);
               }
        }
        return true;
}

public Action:PoCzasieWyjeb(Handle:timer)
{
       KillTimer(TimerUsuwajacy);	
       TimerUsuwajacy = INVALID_HANDLE;
       if(((GetClientCount(false)) == GetMaxClients()) && !SprawdzZioma(ClientDoWyjebania) && IsClientInGame(ClientDoWyjebania))
       {
		  GetClientName(ClientDoWyjebania, SteamID, 64);
              WykopCapa(ClientDoWyjebania);
		  Format(xxa,64,"%s %s",SteamID, "wylecial aby zwolnic slota ziomkom...");
		  PrintToChatAll(xxa);
       }
       return Plugin_Continue;
}

public Action:WykopCapa(client)
{
	GetConVarString(kick_message,xxa,64);
	KickClient(client,xxa);
	return Plugin_Handled;
}

public Action:LoadAllIDs()
{
    IDList = CreateArray(ByteCountToCells(65));
    AutoExecConfig(true,"sloty");
}

public Action:ClearIDs()
{
	ClearArray(IDList);
}
