/* Fixed by Grrrrrrrrrrrrrrrrrrr 

 Fixed:
	some coding to function better

 new features:
	you may add // to comment in the downloads.ini
	you do not need quotes (") around text in the downloads.ini
	Prints to server when a download fails to load

*/
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.1"

public Plugin:myinfo = 
{
	name = "Downloads",
	author = "pRED* & TechKnow",
	description = "Makes Client download files they need",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};


public OnMapStart()
{
	
	//open precache file and add everything to download table
	new String:file[256]
	BuildPath(Path_SM, file, 255, "configs/downloads.ini")
	new Handle:fileh = OpenFile(file, "r")
	new String:buffer[256]
	while (ReadFileLine(fileh, buffer, sizeof(buffer)))
	{
	         if(StrContains(buffer,";")==-1)
	      {
	         if(StrContains(buffer,"//")>-1)
	         SplitString(buffer,"//",buffer,sizeof(buffer));
	         TrimString(buffer);
              }
	         if(!StrEqual(buffer,"",false)&&FileExists(buffer))
	      {
	         AddFileToDownloadsTable(buffer);
	      } 
                 else 
              {
                 PrintToServer("[downloads] Failed: %s",buffer);
	      }
                 if (IsEndOfFile(fileh))
	      {   
                 break
              }
         }
}