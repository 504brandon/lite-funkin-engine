package;

#if desktop
import Discord.DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;

using StringTools;

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	var curSelected:Int = 0;
	var curDifficulty:Int = 1;

	var bg:FlxSprite;
	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Float = 0;
	var intendedScore:Int = 0;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var coolColors:Array<FlxColor> = [
		0xFF9271FD,
		0xFF9271FD,
		0xFF223344,
		0xFF941653,
		0xFFFC96D7,
		0xFFA0D1FF,
		0xFFFF78BF,
		0xFFF6B604,
		0xFF9271FD
	];

	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	private var bg_color:BackgroundColor = new BackgroundColor();

	/**
	 * `haxe.xml.Access` that points to the main `songs` node in `data/freeplay-songs.xml`.
	 */
	public var freeplay_songs:haxe.xml.Access = new haxe.xml.Access(Xml.parse(Assets.getText(Paths.xml('freeplay-songs')))).node.songs;

	override function create():Void
	{
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		if (!FlxG.sound.music.playing)
			FlxG.sound.playMusic(Paths.music('freakyMenu'));

		for (song in freeplay_songs.nodes.song)
		{
			#if !debug
			if (song.att.debug.toLowerCase() != 'true')
				addSong(song.att.name, Std.parseInt(song.att.week), song.att.icon, song.att.diffs.split(','));
			#else
			addSong(song.att.name, Std.parseInt(song.att.week), song.att.icon, song.att.diffs.split(','));
			#end
		}

		// LOAD MUSIC

		// LOAD CHARACTERS

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].songName, true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);

			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);
		}

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		// scoreText.autoSize = false;
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		// scoreText.alignment = RIGHT;

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000);
		scoreBG.antialiasing = false;
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		add(scoreText);

		changeSelection();
		changeDiff();

		super.create();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, ?songDiffs:Array<String>)
	{
		var stupidDiffs:Array<String> = [];
		if (songDiffs != null)
		{
			for (diff in songDiffs)
			{
				stupidDiffs.push(diff.trim());
			}
		}
		else
			stupidDiffs = ['easy', 'normal', 'hard'];

		songs.push(new SongMetadata(songName, weekNum, songCharacter, stupidDiffs));
	}

	public function addWeek(songs:Array<String>, weekNum:Int, ?songCharacters:Array<String>)
	{
		if (songCharacters == null)
			songCharacters = ['bf'];

		var num:Int = 0;
		for (song in songs)
		{
			addSong(song, weekNum, songCharacters[num]);

			if (songCharacters.length != 1)
				num++;
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		lerpScore = CoolUtil.coolLerp(lerpScore, intendedScore, 0.4);

		// i hate this, but interpolating colors without fps shit being annoying is dumb af anyways so
		bg_color.redFloat = CoolUtil.coolLerp(bg_color.redFloat, coolColors[songs[curSelected].week % coolColors.length].redFloat, 0.045);
		bg_color.greenFloat = CoolUtil.coolLerp(bg_color.greenFloat, coolColors[songs[curSelected].week % coolColors.length].greenFloat, 0.045);
		bg_color.blueFloat = CoolUtil.coolLerp(bg_color.blueFloat, coolColors[songs[curSelected].week % coolColors.length].blueFloat, 0.045);

		bg.color = FlxColor.fromRGB(Std.int(bg_color.redFloat * 255.0), Std.int(bg_color.greenFloat * 255.0), Std.int(bg_color.blueFloat * 255.0));

		scoreText.text = "PERSONAL BEST:" + Math.round(lerpScore);
		positionHighscore();

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;

		if (upP)
		{
			changeSelection(-1);
		}
		if (downP)
		{
			changeSelection(1);
		}
		if (FlxG.mouse.wheel != 0)
			changeSelection(-Math.round(FlxG.mouse.wheel / 4));

		if (controls.UI_LEFT_P)
			changeDiff(-1);
		if (controls.UI_RIGHT_P)
			changeDiff(1);

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound("cancelMenu"));
			FlxG.switchState(new MainMenuState());
		}

		if (accepted)
		{
			var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), PlayState.storyDifficulty);

			PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
			PlayState.isStoryMode = false;

			PlayState.storyWeek = songs[curSelected].week;
			trace('CUR WEEK' + PlayState.storyWeek);
			LoadingState.loadAndSwitchState(new PlayState());
		}
	}

	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = songs[curSelected].songDiffs.length - 1;
		if (curDifficulty > songs[curSelected].songDiffs.length - 1)
			curDifficulty = 0;

		PlayState.storyDifficulties = songs[curSelected].songDiffs;
		PlayState.storyDifficulty = PlayState.storyDifficulties[curDifficulty].toUpperCase();
		diffText.text = '< ' + PlayState.storyDifficulty + ' >';
		positionHighscore();

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, PlayState.storyDifficulty);
		#end
	}

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		changeDiff();

		// selector.y = (70 * curSelected) + 30;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, PlayState.storyDifficulty);
		// lerpScore = 0;
		#end

		#if PRELOAD_ALL
		// No clue if this was removed or not, but I wanted to keep this as close as possible to the web version, and this is not in there.
		// Yes, I know it's because the web version doesn't preload everything. If this being gone bothers you so much, then do it yourself lol.
		FlxG.sound.playMusic(Paths.inst(songs[curSelected].songName), 0);
		#end

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
		{
			iconArray[i].alpha = 0.6;
		}

		iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
	}

	function positionHighscore()
	{
		scoreText.x = FlxG.width - scoreText.width - 6;
		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - scoreBG.scale.x / 2;
		diffText.x = scoreBG.x + scoreBG.width / 2;
		diffText.x -= diffText.width / 2;
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var songDiffs:Array<String> = ['easy', 'normal', 'hard'];

	public function new(song:String, week:Int, songCharacter:String, ?songDiffs:Array<String>)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		if (songDiffs != null)
			this.songDiffs = songDiffs;
	}
}

/**
 * because haxe is a bitch ig
 * @author Leather128
 */
class BackgroundColor
{
	public var redFloat:Float = 1.0;
	public var greenFloat:Float = 1.0;
	public var blueFloat:Float = 1.0;

	public function new()
	{
	}
}
