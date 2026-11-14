shader_type sky;

// Skydome's sky with its own clouds (SkydomeClouds2D, clouds_2d.gdshaderinc); clouds of another
// kind (a SkydomeClouds) bring a shader of their own, their clouds between the same two
#include "res://addons/gnd_skydome/sky_common.gdshaderinc"
#include "res://addons/gnd_skydome/clouds_2d.gdshaderinc"
#include "res://addons/gnd_skydome/sky_atmosphere.gdshaderinc"
