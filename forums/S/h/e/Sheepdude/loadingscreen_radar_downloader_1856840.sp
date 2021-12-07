    #include <sourcemod>
    #include <sdktools>
     
    public Plugin:myinfo =
    {
            name            = "Radar and loading screen downloader",
            author          = "Mad",
            description     = "Adds the radar and loading screen files to the downloads table",
            version         = "1.0.1",
            url             = "http://forum.i3d.net/"
    }
     
    /**
     * Add current loading screen to downloads table (will start working next time this map loads.)
     * Add current radar dds file to downloads table
     * Add txt file associsated with radar dds file to downloads table
     */
    public OnMapStart()
    {
            //Get the name of the current map and add it to download table
            new String:mapName[128];
            new String:currentMap[128];
            new String:loadingScreen[128];
            new String:radarTexture[128];
            new String:radarConfig[128];
           
            GetCurrentMap(mapName, sizeof(mapName));
           
            Format(loadingScreen, sizeof(loadingScreen), "resource/flash/loading-%s.swf", mapName);
            Format(radarTexture, sizeof(radarTexture), "resource/overviews/%s_radar.dds", mapName);
            Format(radarConfig, sizeof(radarConfig), "resource/overviews/%s.txt", mapName);
            Format(currentMap, sizeof(currentMap), "maps/%s.bsp", mapName);
           
            if(FileExists(loadingScreen))
                AddFileToDownloadsTable(loadingScreen);
            if(FileExists(radarTexture))
                AddFileToDownloadsTable(radarTexture);
            if(FileExists(radarConfig))
                AddFileToDownloadsTable(radarConfig);
            if(FileExists(currentMap))
                AddFileToDownloadsTable(currentMap);
    }
