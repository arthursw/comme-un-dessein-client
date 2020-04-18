define ['paper', 'R', 'Utils/Utils', 'i18next' ], (P, R, Utils, i18next) ->

	class Camera

        @initialize: ()=>
            console.log('initialize camera')
            require ['three'], (THREE)=>
                window.THREE = THREE
                console.log('three loaded')
                require ['EffectComposer', 'RenderPass', 'ShaderPass', 'grayscaleShader', 'adaptiveThresholdShader', 'vertexShader', 'gui'], (EffectComposer, RenderPass, ShaderPass, grayscaleShader, adaptiveThresholdShader, vertexShader, GUI) =>
                    console.log('everything else loaded')
                    @initializeThreeJS(THREE, EffectComposer, RenderPass, ShaderPass, grayscaleShader, adaptiveThresholdShader, vertexShader, GUI)
                    return
                return
            return
        
        @initializeThreeJS: (THREE, EffectComposer, RenderPass, ShaderPass, grayscaleShader, adaptiveThresholdShader, vertexShader, GUI)=>
            console.log('initializeThreeJS')

            $('#camera').addClass('active')

            # Initialize the scene and our camera
            @scene = new THREE.Scene()
            @camera = new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1)

            threeWidth = window.innerWidth
            threeHeight = window.innerHeight

            # Create the WebGL renderer and add it to the document
            @canvas = document.createElement("canvas")
            @context = canvas.getContext("webgl")

            @renderer = new THREE.WebGLRenderer({
                canvas: @canvas,
                context: @context,
                minFilter: THREE.NearestFilter,
                magFilter: THREE.NearestFilter,
                format: THREE.RGBFormat,
                stencilBuffer: true
            })
            # @renderer = new THREE.WebGLRenderer()

            @renderer.setPixelRatio(window.devicePixelRatio)
            @renderer.setSize(threeWidth, threeHeight)
            document.body.appendChild(@renderer.domElement)

            @video = document.createElement('video')

            # @texture = new THREE.TextureLoader().load('dessin.jpg', resizePlane)

            @texture = new THREE.VideoTexture( @video )

            # @texture.magFilter = THREE.NearestFilter
            # @texture.minFilter = THREE.NearestMipmapNearestFilter
            # @texture.generateMipmaps = true

            @uniforms = {
                time: { type: "f", value: Date.now() },
                resolution: { type: "v2", value: new THREE.Vector2(threeWidth, threeHeight) },
                tDiffuse: { value: @texture },
                threshold1: { value: 0.3 },
                threshold2: { value: 0.3 },
                C: { value: 0.05 },
                windowSize: { value: 15 },
                mousePosition: { value: new THREE.Vector2(0.5, 0.5) }
            }

            @material = new THREE.MeshBasicMaterial({ map: @texture })

            @geometry = new THREE.PlaneGeometry(2, 2)

            @sprite = new THREE.Mesh(@geometry, @material)
            
            @scene.add(@sprite)

            @effectComposer = new THREE.EffectComposer(@renderer)
            @renderPass = new THREE.RenderPass(@scene, @camera)
            # renderPass.clear = false;
            @effectComposer.addPass(@renderPass)

            @grayscaleShaderPass = new THREE.ShaderPass( { uniforms: @uniforms, vertexShader: vertexShader.trim(), fragmentShader: grayscaleShader.trim() } )
            @effectComposer.addPass(@grayscaleShaderPass)

            # @adaptiveThresholdShaderPass = new THREE.ShaderPass( { uniforms: @uniforms, vertexShader: vertexShader.trim(), fragmentShader: adaptiveThresholdShader.trim() } )
            # @effectComposer.addPass(@adaptiveThresholdShaderPass)

            window.addEventListener("resize", @onWindowResize, false)
            $('#camera').append(@canvas)
            @animate()
            
            if navigator.mediaDevices and navigator.mediaDevices.getUserMedia

                constraints = { video: { width: 400, height: 400, facingMode: 'user' } }

                navigator.mediaDevices.getUserMedia( constraints ).then( ( stream ) =>
                    # apply the stream to the video element used in the texture
                    @video.srcObject = stream
                    @video.play()
                ).catch( ( error ) ->
                    console.error( 'Unable to access the camera/webcam.', error )
                )
            else
                console.error( 'MediaDevices interface not available.' )

            @gui = new dat.GUI({ autoPlace: false })
            @gui.add(@grayscaleShaderPass.uniforms.threshold1, 'value', 0, 1, 0.01).name('Threshold 1')
            @gui.add(@grayscaleShaderPass.uniforms.threshold2, 'value', 0, 1, 0.01).name('Threshold 1')
            $('#camera').append(@gui.domElement)
            $(@gui.domElement).css( 'z-index': 10002, position: 'absolute', right: 0, bottom: 0 )

            $('#cancel-photo').click(@cancelPhoto)
            $('#take-photo').click(@cancelPhoto)
            return

        @cancelPhoto: ()=>
            @remove()
            return

        @takePhoto: ()=>
            @renderer.domElement.toBlob (blob) =>
                image = new Image()
                reader = new FileReader()
                reader.onload = (e) =>
                    image.src = e.target.result
                    image.onload = () =>
                        imageCanvas = document.createElement("canvas")

                        width = Math.floor(image.width)
                        height = Math.floor(image.height)

                        imageCanvas.width = width
                        imageCanvas.height = height
                        context = imageCanvas.getContext('2d')
                        context.drawImage(image, 0, 0, width, height)

                        imageData = context.getImageData(0, 0, width, height).data
                        traceHomeMadeProcess(imageData, width, height)
                        return
                    return
                return
            reader.readAsDataURL(blob)
            @remove()
            return
        
        @resizePlane: ()=>
            # Make sure image is loaded and has dimensions
            if@texture.image and @texture.image.naturalWidth > 0 and @texture.image.naturalHeight > 0
                # Note: must multiply by two to have real size ; but here we want to get half the size
                newPlaneGeometry = new THREE.PlaneGeometry(texture.image.naturalWidth / window.innerWidth, texture.image.naturalHeight / window.innerHeight);
                geometry.vertices = newPlaneGeometry.vertices;
                geometry.verticesNeedUpdate = true;
            return

        @onWindowResize: ()=>
            threeWidth = window.innerWidth
            threeHeight = window.innerHeight
            @renderer.setSize(threeWidth, threeHeight);
            @effectComposer.setSize(threeWidth, threeHeight);
            @resizePlane()
            return
        
        @animate: (timestamp = 0)=>
            if @renderer?
                requestAnimationFrame(@animate)
                @effectComposer.render()
            return
        
        @remove: ()=>
            $('#camera').hide()
            $(@renderer.domElement).remove()
            $(@gui.domElement).remove()
            $(@canvas).remove()
            $(@video).remove()
            @renderer = null
            @scene = null
            @canvas = null
            @context = null
            @sprite = null
            @material = null
            @geometry = null
            @effectComposer = null
            @renderPass = null
            @grayscaleShaderPass = null
            return

		constructor: ()->
			return
		
	return Camera
