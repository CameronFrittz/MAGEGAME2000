shader_type canvas_item;
void vertex() {
VERTEX += vec2(cos(TIME)*50.0, sin(TIME)*550.0);	// Called for every vertex the material is visible on.
}
