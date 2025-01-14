package levels;

import echo.Collider;
import echo.Body;
import echo.World;
import tyke.Graphics.RectangleGeometry;
import pieces.Obstacle;
import tyke.Ldtk.LevelLoader;
import tyke.Graphics.SpriteRenderer;

class LevelManager {
	var tracks:Tracks;
	var levelSprites:SpriteRenderer;
	var obstacleSprites:SpriteRenderer;
	var largeSprites:SpriteRenderer;
	var world:World;
	var levelId:Int;
	var tilePixelSize:Int;
	var totalEnemiesRemaining:Int;

	public var minY(default, null):Int;
	public var maxY(default, null):Int;
    public var obstacleBodies(default, null):Array<Body>;
	public var enemyTriggerZones(default, null):Array<Body>;
	public var endTriggerZones(default, null):Array<Body>;
	
	public function new(levelSprites:SpriteRenderer, largeSprites:SpriteRenderer, tilePixelSize:Int, world:World, levelId:Int) {
		this.levelSprites = levelSprites;
		// this.obstacleSprites = obstacleSprites;
		this.largeSprites = largeSprites;
		this.tilePixelSize = tilePixelSize;
		this.world = world;
		this.levelId = levelId;
        obstacleBodies = [];
		enemyTriggerZones = [];
		endTriggerZones = [];
		minY = 4 * 32;
		maxY = 420 - minY;
		tracks = new Tracks();

		setupTrackTiles();
		
		setupObstacles();

		setupEnemyTriggers();

		setupFinishLine();
	}

	/**
		converts the tile ID from the tile map used in ldtk to the CollisionType enum for use in game 
	**/
	inline function determineCollisionType(tileId:Int):CollisionType {
		return switch tileId {
			case 9: RAMP;
			case 8: HOLE;
			case _: UNDEFINED;
		}
	}

	function setupTrackTiles() {
		var beachTileMap = tracks.levels[levelId].l_Track;
		LevelLoader.renderLayer(beachTileMap, (stack, cx, cy) -> {
			for (tileData in stack) {
				var tileX = cx * tilePixelSize;
				var tileY = cy * tilePixelSize;
				this.levelSprites.makeSprite(tileX, tileY, tilePixelSize, tileData.tileId);
			}
		});

	}

	function setupObstacles() {
		var obstacleTileMap = tracks.levels[levelId].l_Obstacles;
		LevelLoader.renderLayer(obstacleTileMap, (stack, cx, cy) -> {
			for (tileData in stack) {
				var tileX = cx * tilePixelSize;
				var tileY = cy * tilePixelSize;
				var geometry:RectangleGeometry = {
					y: tileY,
					x: tileX,
					width: tilePixelSize,
					height: tilePixelSize
				}

				var obstacleType = determineCollisionType(tileData.tileId);
				var largeIndex = switch obstacleType{
					case RAMP: 6;
					case HOLE: 12;
					case _: 6;
				};

				var sprite = this.largeSprites.makeSprite(tileX, tileY, 96, largeIndex);
				var obstacle = new Obstacle(obstacleType, geometry, world, sprite);

				// obstacleBodies array used for collision listener
				obstacleBodies.push(obstacle.body);

                // trace('triggered Obstacle $obstacleType x $tileX y $tileY');
			}
		});
	}

	function setupEnemyTriggers() {
		var triggerZones = tracks.levels[levelId].l_HitBoxes.all_EnemyTrigger;
		totalEnemiesRemaining = triggerZones.length;
		for(triggerZone in triggerZones){
			// adjust position and size for 32 pixel grid (map is made with 16 pixels)
			var x = triggerZone.cx * tilePixelSize;
			var y = triggerZone.cy * tilePixelSize;
			var w = triggerZone.width * 2;
			var h = triggerZone.height * 2;
			var hitZone = new Body({
				shape: {
					solid: false,
					width: w,
					height: h,
				},
				kinematic: true,
				mass: 0,
				x: x + (w * 0.5), // need to add half the width to position correctly (because body origin is in center)
				y: y + (h * 0.5), // need to add half the height to position correctly (because body origin is in center)
				rotation: 1 // needed to render debug (bug in rectangle render)
			});

			// register body in world
			world.add(hitZone);

			// enemyTriggerZones use in collision listener
			enemyTriggerZones.push(hitZone);
		}
	}

	function setupFinishLine() {
		var endZones = tracks.levels[levelId].l_HitBoxes.all_EndTrigger;
		for(endZone in endZones) {
			var x = endZone.cx * tilePixelSize;
			var y = endZone.cy * tilePixelSize;
			var w = endZone.width * 2;
			var h = endZone.height * 2;

			var endHitZone = new Body({
				shape: {
					solid: false,
					width: w,
					height: h,
				},
				kinematic: true,
				mass: 0,
				x: x + (w * 0.5),
				y: y + (h * 0.5),
				rotation: 1
			});

			world.add(endHitZone);
			endTriggerZones.push(endHitZone);
		}
	}

	public function registerLostOneEnemy() {
		totalEnemiesRemaining--;
	}

	public function isWon():Bool {
		return totalEnemiesRemaining <= 0;
	}

}
