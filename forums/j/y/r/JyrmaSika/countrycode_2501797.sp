/*
  Player Country Codes
  Author: Jyrma Sika
  Forked from malfunctioning Country Nick Plugin by Antoine LIBERT aka AeN0


  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <geoip>

#define VERSION "0.2"

public Plugin:myinfo =
{
  name = "Player Country Codes",
  author = "Jyrma Sika. Original version Antoine LIBERT aka AeN0",
  description = "Player Country Codes Forked from Country Nick Plugin",
  version = VERSION,
  url = "https://www.facepalm.fi"
};

public OnPluginStart()
{
  LoadTranslations("countrynick.phrases");
}


public OnClientConnected(client)
{
  if (IsFakeClient(client)) {
    return;
  }

  SetPlayerCountryCode(client);
}

// Just to make sure the country code prefix is added
public OnClientAuthorized(client, const String:auth[])
{
  if (IsFakeClient(client)) {
    return;
  }

  SetPlayerCountryCode(client);
}

public SetPlayerCountryCode(client)
{
  if(!IsFakeClient(client))
    {      
      decl String:newname[69];
      decl String:nick[69];
      decl String:flag[5];
      
      GetClientInfo(client, "name", newname, 69);
      
      getFlagOfPlayer(client, flag, 5);
      if(strncmp(flag, newname, 4, false) == 0) {
      }
      else {
	Format(nick, 69, "%2s%s", flag, newname);
	SetClientName(client, nick);
      }
    }  
}

getFlagOfPlayer(client, String:flag[], size)
{
  decl String:ip[16];
  decl String:code2[3];
  
  GetClientIP(client, ip, 16);
  if(GeoipCode2(ip, code2))
    {
      Format(flag, size, "[%2s]", code2);
      return true;
    }
  else
    {
      Format(flag, size, "[--]");
      return false;
    }
}

