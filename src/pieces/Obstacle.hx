package pieces;

import echo.Collider;
import tyke.Graphics;
import tyke.Graphics.SpriteRenderer;
import echo.Body;
import echo.World;
import tyke.Graphics.RectangleGeometry;


class Obstacle{
    public var body(default, null):Body;
    var sprite:Sprite;
    var type:CollisionType;

    public function new(type:CollisionType, geometry:RectangleGeometry, world:World, sprite:Sprite){
        this.type = type;
        this.sprite = sprite;

        body = new Body({
            shape: {
                width: geometry.width,
                height: geometry.height
            },
            kinematic: true,
            mass: 1,
            x: geometry.x,
            y: geometry.y,
            rotation: 1 // because of bug in debug renderer
        });
        
        // bind movement in case we add moving obstacles
        body.on_move = (x, y) -> sprite.setPosition(x, y);
        
        // store reference to Collider helper class for use in collisions
        body.collider = new Collider(type, body -> collideWith(body));

        // register body in physics simulation
        world.add(body);
    }


	function collideWith(body:Body) {
        // todo
        trace("obstacle collide");
        if(body.collider.type == VEHICLE){
            this.body.remove();
        }
    }
}