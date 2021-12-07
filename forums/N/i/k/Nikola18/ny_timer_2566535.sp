/*
	TS2018 - не изменять
	Запустите плагин, посмотрите на выводимую дату, сравните со временем на этом сайте:
	http://доновогогода.рф/
	Скорректируйте TSOFFS на нужное кол-во часов.
	
	Полезные символы для оформления:
	❄  ❆  ❅ ★ ❄  ❆  ❅ ★ ✫ ✬ ✭ ✮ ✯ ✰ ✱ ✲ ✳ ✴ ✵ ✶ ✷ ✸ ✹ ✺ ✻ ✼ ✽ ✾ ✿ ❀ ❁ ❂ ❃ ❇ ❈ ❉ ❊ ❋
	Список цветов в чате: 
	https://forums.alliedmods.net/showpost.php?p=2271367&postcount=3
*/

#define TS2018 1514764800
#define TSOFFS -10

public Plugin myinfo = {
    name = "New Year Timeleft",
	author = "diller110 & 1mpulse & IceBoom"
};

public void OnPluginStart() {
    CreateTimer(5.0, StartTimer_CallBack);
}

public Action StartTimer_CallBack(Handle timer) {
	PrintTimer();
	CreateTimer(GetRandomFloat(300.0, 600.0), StartTimer_CallBack);
}

stock void PrintTimer(int offset = TSOFFS) {
	int sec = TS2018 - GetTime()+TSOFFS*3600;
	if (sec > 0) {
	switch (GetRandomInt(1,9)) {
		case 2: {
			PrintToChatAll(" \x0B❄❅❄ \x01Before the New Year: \x0B%d\x08d. \x0B%d\x08h. \x0B%d\x08m. \x0B%02d\x08sec.", sec/3600/24, sec/3600%24, sec/60%60, sec%60);
		}
		case 3: {
		
			PrintToChatAll(" \x01✲\x07❅\x01✲ \x01Before the New Year: \x07%d\x08d. \x07%d\x08h. \x07%d\x08m. \x07%02d\x08sec.", sec/3600/24, sec/3600%24, sec/60%60, sec%60);
		}
		case 4: {
		
			PrintToChatAll(" \x06❊\x09❉\x0B❋ \x01Before the New Year: \x06%d\x08d. \x0B%d\x08h. \x07%d\x08m. \x09%02d\x08sec.", sec/3600/24, sec/3600%24, sec/60%60, sec%60);
		}
		case 5: {
		
			PrintToChatAll(" \x0F✲✺✲ \x01Before the New Year: \x0F%d\x08d. \x0F%d\x08h. \x0F%d\x08m. \x09%02d\x08sec.", sec/3600/24, sec/3600%24, sec/60%60, sec%60);
		}
		case 6: {
		
			PrintToChatAll(" \x05✳✴✵ \x01Before the New Year: \x05%d\x08d. \x05%d\x08h. \x05%d\x08m. \x05%02d\x08sec.", sec/3600/24, sec/3600%24, sec/60%60, sec%60);
		}
		case 7: {
		
			PrintToChatAll(" \x04✻✼✽ \x01Before the New Year: \x08%d\x08d. \x08%d\x08h. \x08%d\x08m. \x08%02d\x08sec.", sec/3600/24, sec/3600%24, sec/60%60, sec%60);
		}
		case 8: {
		
			PrintToChatAll(" \x09❄\x06✽\x09✻ \x01Before the New Year: \x09%d\x08d. \x09%d\x08h. \x09%d\x08m. \x09%02d\x08sec.", sec/3600/24, sec/3600%24, sec/60%60, sec%60);
		}
	   default: {
            PrintToChatAll(" \x06✷✹✷ \x01Before the New Year: \x06%d\x08d. \x06%d\x08h. \x06%d\x08m. \x06%02d\x08sec.", sec/3600/24, sec/3600%24, sec/60%60, sec%60);
        }
	 }
  }
	else {
		switch (GetRandomInt(1,5)) {
			case 2: {
            	PrintToChatAll(" \x0B❅✵✺ \x01Happy New Year! \x0B❅✵✺");
            }
            case 3: {
            	PrintToChatAll(" \x06✷✹✷ \x01Happy New Year! \x06✷✹✷");
            }
			case 4: {
            	PrintToChatAll(" \x07✲\x01❅\x07✲ \x01Happy New Year! \x07✲\x01❅\x07✲");
            }
			case 5: {
            	PrintToChatAll(" \x06❊\x01❉\x0B❋ \x01Happy New Year! \x06❊\x01❉\x0B❋");
            }
            default: {
            	PrintToChatAll(" \x0F✲✺✲ \x01Happy New Year! \x0F✲✺✲");
            }
        }
    }
}