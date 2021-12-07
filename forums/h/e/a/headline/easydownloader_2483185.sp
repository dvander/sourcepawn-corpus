#include <sourcemod>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

// Plugin Informaiton  
#define VERSION "1.00"

//Paths
#define PATH_BASE "configs/easydownloader/"

//Mode
#define MODE_DECALS 0
#define MODE_GENERICS 1
#define MODE_MODELS 2
#define MODE_SENTENCEFILES 3
#define MODE_SOUNDS 4

char modeNiceNames[5][255];

public Plugin myinfo =
{
  name = "Easy Downloader",
  author = "Invex | Byte",
  description = "Download/Precache Files.",
  version = VERSION,
  url = "http://www.invexgaming.com.au"
};

public void OnPluginStart()
{
	modeNiceNames[MODE_DECALS] = "decals.txt";
	modeNiceNames[MODE_GENERICS] = "generics.txt";
	modeNiceNames[MODE_MODELS] = "models.txt";
	modeNiceNames[MODE_SENTENCEFILES] = "sentencefiles.txt";
	modeNiceNames[MODE_SOUNDS] = "sounds.txt";
}

public void OnMapStart()
{
  //Process all files
	processFile(MODE_DECALS);
	processFile(MODE_GENERICS);
	processFile(MODE_MODELS);
	processFile(MODE_SENTENCEFILES);
	processFile(MODE_SOUNDS);
}

public void processFile(int mode)
{
	char finalpath[PLATFORM_MAX_PATH];
	Format(finalpath, sizeof(finalpath), "%s%s", PATH_BASE, modeNiceNames[mode]);
	BuildPath(Path_SM, finalpath, PLATFORM_MAX_PATH, finalpath);
	
	if (FileExists(finalpath))
	{
		//Open file
		File file = OpenFile(finalpath, "r");
		
		if (file != null)
		{
			char buffer[1024];
      
			//For each file in the text file
			while (file.ReadLine(buffer, sizeof(buffer)) && !file.EndOfFile()) 
			{
				//Remove final new line
				//buffer length > 0 check needed in case file is completely empty and there is no new line '\n' char after empty string ""
				if (strlen(buffer) > 0 && buffer[strlen(buffer) - 1] == '\n')
					buffer[strlen(buffer) - 1] = '\0';

				//Remove any whitespace at either end
				TrimString(buffer);

				//Ignore empty lines
				if (strlen(buffer) == 0)
					continue;
				  
				//Ignore comment lines
				if (StrContains(buffer, "//") == 0)
					continue; 

				//Proceed if file exists
				if (FileExists(buffer))
				{
					AddFileToDownloadsTable(buffer);
					if (mode == MODE_DECALS)
						PrecacheDecal(buffer, true);
					else if (mode == MODE_GENERICS)
						PrecacheGeneric(buffer, true);
					else if (mode == MODE_MODELS)
						PrecacheModel(buffer, true);
					else if (mode == MODE_SENTENCEFILES)
						PrecacheSentenceFile(buffer, true);
					else if (mode == MODE_SOUNDS)
						PrecacheSound(buffer, true);
				}
				else 
				{
					LogError("File '%s' does not exist. Please check entry in file: '%s'", buffer, modeNiceNames[mode]);
				}
			}
			
			delete file;
        }
	}
	else
	{
		LogError("Missing required file: '%s'", finalpath);
	}
}