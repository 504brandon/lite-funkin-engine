package;

import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;

class HEY extends MusicBeatState
{
	override function create()
	{
		var bg:FlxSprite = new FlxSprite(null, null, Paths.image('menuDesat'));
		bg.scrollFactor.x = 0;
		bg.scrollFactor.y = 0.17;
		bg.setGraphicSize(Std.int(bg.width * 1.2));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = true;
		bg.color = 0x1F1F1D;
		add(bg);

		var warn = new FlxText();
		warn.text = "hey this engine is in github beta and isnt even 1% complete\nthis is supposed what my former engine 'dike engine' was supposed to be\nthere will be many bugs and it is likely unstable\nif you understand you can press enter to go to title state.\nbut if you want to see my former engine press escape";
		warn.alignment = CENTER;
		warn.scale.set(2.3, 2.3);
		warn.updateHitbox();
		warn.screenCenter();
		add(warn);
	}

	override public function update(elapsed:Float)
	{
		if (FlxG.keys.justPressed.ENTER)
		{
			FlxG.switchState(new TitleState());
		}
		if (FlxG.keys.justPressed.ESCAPE)
			CoolUtil.openURl('https://github.com/504brandon/dike-engine/');
	}
}
