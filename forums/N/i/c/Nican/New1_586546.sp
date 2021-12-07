#pragma semicolon 1;
#include <sourcemod>

new frames;
new fps;
new Float:nexttime;

public Plugin:myinfo = 
{
    name = "FPS shower",
    author = "Nican132",
    description = "Shows the FPS every 2 min.",
    version = "1.0",
    url = "http://www.nican132.com/"
};



public OnGameFrame(){
    frames++;
    
    new Float:newtime = GetEngineTime();
    if(newtime >= nexttime){
        fps = frames;
        frames = 0;    
        nexttime = newtime + 1.0;
        
        LogMessage("FPS: %d", fps);
    }
}
