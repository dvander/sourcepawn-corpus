#include <sourcemod>
#include <sdktools>
#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "0.1.0 beta"

public Plugin:myinfo = {
	name        = "[TF2] MW2Renamer",
	author      = "SqTH (thx to Crazydog and Thraka)",
	description = "Automatically remove colors characters of MW2 players. Based on Free or Premium Renamer by Crazydog, and Colored Names by Thraka (Original by Afronanny)",
	version     = PLUGIN_VERSION
};
public OnClientPostAdminCheck(client)
{	
  //exclude bots ?
	if (IsFakeClient(client))
	{
		return;
	}
	
	//create string
  new String:name[MAX_NAME_LENGTH];
    
  //take name's player
  GetClientName(client, name, sizeof(name));
    
  //replaces characters that players use for coloring in MW2
  ReplaceString(name, sizeof(name), "^0", "");
  ReplaceString(name, sizeof(name), "^1", "");
  ReplaceString(name, sizeof(name), "^2", "");
  ReplaceString(name, sizeof(name), "^3", "");
  ReplaceString(name, sizeof(name), "^4", "");
  ReplaceString(name, sizeof(name), "^5", "");
  ReplaceString(name, sizeof(name), "^6", "");
  ReplaceString(name, sizeof(name), "^7", "");
  ReplaceString(name, sizeof(name), "^8", "");
  ReplaceString(name, sizeof(name), "^9", ""); 


	//update name
	SetClientInfo(client, "name", name);		

  //w00t ?
	return;
}
