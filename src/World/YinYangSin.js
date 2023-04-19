import Experience from "../Experience";
import YinYangVertexShader from "../Shaders/YinYang/YinYangVertexShader.glsl"
import YinYangSinFragmentShader from "../Shaders/YinYang/YinYangSinFragmentShader.glsl"
import DepthVertexShader from "../Shaders/DepthVertexShader.glsl"
import YinYangSinDepthFragmentShader from "../Shaders/YinYang/YinYangSinDepthFragmentShader.glsl"
import * as THREE from "three"

export default class YinYangSin {
    constructor(world) {
        this.experience    = new Experience();
        this.scene         = this.experience.scene;
        this.audioAnalizer = this.experience.audioAnalizer;
        this.time          = this.experience.time;
        this.world         = world;
        
        this.setup();
    }

    setup() {
        this.geometry = new THREE.PlaneGeometry(3, 3);


        this.material = new THREE.ShaderMaterial({
            uniforms : {
                uAudioTexture  : { value : this.audioAnalizer.bufferCanvasLinear.texture },
                uHighFrequency : { value : 0 },
                uLowFrequency  : { value : 0 },
                uTime          : { value : 0 },
                uAlpha         : { value : this.experience.debugOptions.yinYangAlpha },
                uRotate        : { value : 1.0 },
                uHover         : { value : 0.0 },
                uColorStrength : { value : 0   }
            },
            vertexShader    : YinYangVertexShader,
            fragmentShader  : YinYangSinFragmentShader,
            transparent     : true, 
            side            : THREE.DoubleSide,
            depthWrite      : false
        });
        this.mesh = new THREE.Mesh(this.geometry, this.material);
        this.mesh.position.y += 7;
        this.mesh.position.x += 1;
        this.mesh.name = "YinYangSin";
        this.mesh.castShadow =  this.experience.debugOptions.shadows;

        // Custom depth material
        this.mesh.customDepthMaterial = new THREE.MeshDepthMaterial({ 
            depthPacking: THREE.RGBADepthPacking
        });

        // Need this structure formed on the first updates, when customDepthMaterial is compiled
        // is filled with the real values
        this.mesh.customDepthMaterial.uniforms = { uTime : { value : 0.0 }};
        // Modify the default depth material
        this.mesh.customDepthMaterial.onBeforeCompile = (shader) => {
            shader.uniforms.uAudioTexture  = { value : this.audioAnalizer.bufferCanvasLinear.texture };
            shader.uniforms.uHighFrequency = { value : 0 };
            shader.uniforms.uLowFrequency  = { value : 0 };
            shader.uniforms.uTime          = { value : 0 };
            shader.uniforms.uAlpha         = { value : this.experience.debugOptions.yinYangAlpha };
            shader.uniforms.uRotate        = { value : 1.0 };
            shader.uniforms.uHover         = { value : 0.0 };
            shader.uniforms.uColorStrength = { value : 0   };
            shader.vertexShader            = DepthVertexShader;
            shader.fragmentShader          = YinYangSinDepthFragmentShader;
            this.mesh.customDepthMaterial.uniforms = shader.uniforms;
        }

        this.scene.add(this.mesh);

    }

    update() {
        // Divided by 1024 to get values from 0.0 to 0.25
        this.material.uniforms.uHighFrequency.value = (255 - this.audioAnalizer.averageFrequency[0]) / 5024;
        this.material.uniforms.uLowFrequency.value  = this.audioAnalizer.averageFrequency[2] / 5024;
        this.material.uniforms.uColorStrength.value = 0.125 + this.audioAnalizer.averageFrequency[2] / 192;
        this.material.uniforms.uTime.value         += this.time.delta / 1000;
        this.mesh.customDepthMaterial.uniforms.uTime.value = this.material.uniforms.uTime.value;
    }
}