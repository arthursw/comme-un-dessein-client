define ['paper', 'R', 'Utils/Utils', 'i18next' ], (P, R, Utils, i18next) ->

	class Camera

        @threeSize = Math.min(window.innerWidth, window.innerHeight) # 900
        @initialized = false

        @initialize: ()=>
            console.log('initialize camera')
            require ['three'], (THREE)=>
                window.THREE = THREE
                console.log('three loaded')
                require ['EffectComposer', 'RenderPass', 'ShaderPass', 'paletteShader', 'adaptiveThresholdShader', 'thresholdShader', 'separateColorsShader', 'stripesShader', 'erodeShader', 'vertexShader', 'gui'], (EffectComposer, RenderPass, ShaderPass, paletteShader, adaptiveThresholdShader, thresholdShader, separateColorsShader, stripesShader, erodeShader, vertexShader, GUI) =>
                    console.log('everything else loaded')
                    @initializeThreeJS(THREE, EffectComposer, RenderPass, ShaderPass, paletteShader, adaptiveThresholdShader, thresholdShader, separateColorsShader, stripesShader, erodeShader, vertexShader, GUI)
                    return
                return
            return
        
        @initializeThreeJS: (THREE, EffectComposer, RenderPass, ShaderPass, paletteShader, adaptiveThresholdShader, thresholdShader, separateColorsShader, stripesShader, erodeShader, vertexShader, GUI)=>
            console.log('initializeThreeJS')

            $('#camera').show()
            $('#camera').addClass('active')

            # Initialize the scene and our camera
            @scene = new THREE.Scene()
            @camera = new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1)
            @stream = null

            threeWidth = window.innerWidth
            threeHeight = window.innerHeight
            # threeWidth = @threeSize
            # threeHeight = @threeSize
            minDimension = Math.min(threeWidth, threeHeight)

            # Create the WebGL renderer and add it to the document
            @canvas = document.createElement("canvas")
            # $(@canvas).attr('id', 'camera-canvas')
            $(@canvas).css({    
                top: '50%',
                left: '50%',
                transform: 'translate(-50%, -50%)'
            })

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

            @renderer.setPixelRatio(1)
            @renderer.setSize(minDimension, minDimension)
            document.body.appendChild(@renderer.domElement)

            @video = document.createElement('video')

            # @texture = new THREE.TextureLoader().load('dessin.jpg', resizePlane)

            @texture = new THREE.VideoTexture( @video )

            # @texture.magFilter = THREE.NearestFilter
            # @texture.minFilter = THREE.NearestMipmapNearestFilter
            # @texture.generateMipmaps = true
            red = '#F44336'
            blue = '#448AFF'
            green = '#8BC34A'
            yellow = '#FFC107'
            # // let brown = '#795548'
            brown = '#704433'
            # // let brown = '#006633'
            white = '#FFFFFF'
            black = '#000000'
            colors = [red, blue, green, yellow, brown, black, white]
            if R.isCommeUnDessein or not R.useColors
                colors = [black, black, black, black, black, black, white]
            colorVectorArray = []

            for color in colors
                c = new THREE.Color(color)
                colorVectorArray.push(new THREE.Vector3(c.r, c.g, c.b))

            @uniforms = {
                time: { type: "f", value: Date.now() },
                label: { type: "b", value: false },
                resolution: { type: "v2", value: new THREE.Vector2(minDimension, minDimension) },
                tDiffuse: { value: @texture },
                hue: { value: 0.0 },
                saturation: { value: 0.0 },
                lightness: { value: 0.0 },
                C: { value: 0.05 },
                threshold: { value: 0.5 },
                windowSize: { value: 15 },
                stripeWidth: { value: 5 },
                mousePosition: { value: new THREE.Vector2(0.5, 0.5) }
                colors: { type: "v3v", value: colorVectorArray },
            }

            @material = new THREE.MeshBasicMaterial({ map: @texture })

            @geometry = new THREE.PlaneGeometry(2, 2)

            @sprite = new THREE.Mesh(@geometry, @material)
            
            @scene.add(@sprite)

            @effectComposer = new THREE.EffectComposer(@renderer)
            @renderPass = new THREE.RenderPass(@scene, @camera)
            # renderPass.clear = false;
            @effectComposer.addPass(@renderPass)

            # @paletteShaderPass = new THREE.ShaderPass( { uniforms: @uniforms, vertexShader: vertexShader.trim(), fragmentShader: paletteShader.trim() } )
            # @effectComposer.addPass(@paletteShaderPass)
            # console.log('create @paletteShaderPass:', @paletteShaderPass)
            # @paletteShaderPass.enabled = false

            # @separateColorsShaderPass = new THREE.ShaderPass( { uniforms: @uniforms, vertexShader: vertexShader.trim(), fragmentShader: separateColorsShader.trim() } )
            # @effectComposer.addPass(@separateColorsShaderPass)
            # @separateColorsShaderPass.enabled = false

            # @erodeShaderPass = new THREE.ShaderPass( { uniforms: @uniforms, vertexShader: vertexShader.trim(), fragmentShader: erodeShader.trim() } )
            # @effectComposer.addPass(@erodeShaderPass)
            # @effectComposer.addPass(@erodeShaderPass)
            # @effectComposer.addPass(@erodeShaderPass)
            # @erodeShaderPass.enabled = false
            
            # @adaptiveThresholdShaderPass = new THREE.ShaderPass( { uniforms: @uniforms, vertexShader: vertexShader.trim(), fragmentShader: adaptiveThresholdShader.trim() } )
            # @effectComposer.addPass(@adaptiveThresholdShaderPass)
            # @adaptiveThresholdShaderPass.enabled = false

            @thresholdShaderPass = new THREE.ShaderPass( { uniforms: @uniforms, vertexShader: vertexShader.trim(), fragmentShader: thresholdShader.trim() } )
            @effectComposer.addPass(@thresholdShaderPass)
            @thresholdShaderPass.enabled = true

            @stripesShaderPass = new THREE.ShaderPass( { uniforms: @uniforms, vertexShader: vertexShader.trim(), fragmentShader: stripesShader.trim() } )
            @effectComposer.addPass(@stripesShaderPass)
            @stripesShaderPass.enabled = false


            window.addEventListener("resize", @onWindowResize, false)
            $('#camera').prepend(@canvas)
            @animate()
            
            if navigator.mediaDevices and navigator.mediaDevices.getUserMedia

                constraints = { video: { width: 300, height: 300, facingMode: 'environment' } }
                # constraints = { video: { facingMode: 'environment' } }

                navigator.mediaDevices.getUserMedia( constraints ).then( ( stream ) =>
                    # apply the stream to the video element used in the texture
                    @stream = stream
                    @video.srcObject = stream
                    @video.play()
                ).catch( ( error ) ->
                    console.error( 'Unable to access the camera/webcam.', error )
                )
            else
                console.error( 'MediaDevices interface not available.' )

            # @gui = new dat.GUI({ autoPlace: false })
            # @gui.add(@paletteShaderPass.uniforms.saturation, 'value', -1, 1, 0.01).name('Saturation')
            # @gui.add(@paletteShaderPass.uniforms.lightness, 'value', -1, 1, 0.01).name('Lightness')
            # $('#camera').append(@gui.domElement)
            # $(@gui.domElement).css( 'z-index': 10002, position: 'absolute', right: 0, bottom: 0 )

            if not @initialized
                $('#cancel-photo').click(@cancelPhoto)
                $('#take-photo').click(@takePhoto)

                @sliders ?= {}
                # @initializeSliders('saturation')
                # @initializeSliders('lightness')
                @initialized = true

                $('#camera').mousemove((event)=> 
                    event.preventDefault()
                    event.stopPropagation()
                    return -1)
            return

        @initializeSliders: (name)=>
            sliderJ = $('.cd-slider.' + name)
            sliderJ.find('.btn.minus').click(()=> @addParameter(name, -5))
            sliderJ.find('.btn.plus').click(()=> @addParameter(name, 5))
            sliderJ.find('.cd-inline').click((event)=> @setParameter(name, event))
            @sliders[name] = { dragging: false }
            sliderJ.find('.cd-inline').mousedown(()=> @sliders[name].dragging = true)
            sliderJ.find('.cd-inline').mousemove((event)=> 
                if @sliders[name].dragging 
                    @setParameter(name, event) 
                    event.preventDefault()
                    event.stopPropagation()
                return -1)
            $(window).mouseup(()=> @sliders[name].dragging = false)
            return

        @updateSlider: (name, value)=>
            iconJ = $('.cd-slider.' + name + ' .cd-inline .glyphicon')
            percent = Math.round((1 + value) * 0.5 * 100)
            iconJ.css(left: percent + '%')
            line1J = $('.cd-slider.' + name + ' .cd-inline .cd-line:first-child')
            line1J.css(width: 'calc(' + percent + '% - 20px)')
            line2J = $('.cd-slider.' + name + ' .cd-inline .cd-line:last-child')
            line2J.css(width: 'calc(' + (100 - percent) + '% - 20px)', left: percent + '%')
            return

        @addParameter: (name, delta)=>
            value = @paletteShaderPass.uniforms[name].value + (delta / 100) * 2
            if value < -1
                value = -1
            if value > 1
                value = 1
            @paletteShaderPass.uniforms[name].value = value 
            @updateSlider(name, value)
            return
        
        @setParameter: (name, event)=>
            lineJ = $('.cd-slider.' + name + ' .cd-inline')
            value = (event.clientX - lineJ.offset().left) / lineJ.width()
            value = -1 + 2 * value
            @paletteShaderPass.uniforms[name].value = value
            @updateSlider(name, value)
            return

        @cancelPhoto: ()=>
            @remove()
            return

        @takePhoto: ()=>
            # @paletteShaderPass.enabled = true
            # # @paletteShaderPass.uniforms.label.value = true

            # @separateColorsShaderPass.enabled = true
            # @erodeShaderPass.enabled = true
            # @adaptiveThresholdShaderPass.enabled = true
            @thresholdShaderPass.enabled = true
            # @stripesShaderPass.enabled = true

            @effectComposer.render()
            R.tracer.imageURL = @renderer.domElement.toDataURL()

            # @paletteShaderPass.enabled = true
                
            # @separateColorsShaderPass.enabled = false
            # @erodeShaderPass.enabled = false
            # @stripesShaderPass.enabled = false

            # @paletteShaderPass.uniforms.label.value = false
            @remove()
            R.tracer.setEditImageMode()
            return
        # @takePhoto: ()=>
        #     @renderer.domElement.toBlob (blob) =>
        #         image = new Image()
        #         reader = new FileReader()
        #         reader.onload = (e) =>
        #             image.src = e.target.result
        #             image.onload = () =>
        #                 imageCanvas = document.createElement("canvas")

        #                 width = Math.floor(image.width)
        #                 height = Math.floor(image.height)

        #                 imageCanvas.width = width
        #                 imageCanvas.height = height
        #                 context = imageCanvas.getContext('2d')
        #                 context.drawImage(image, 0, 0, width, height)

        #                 imageData = context.getImageData(0, 0, width, height).data
        #                 traceHomeMadeProcess(imageData, width, height)
        #                 return
        #             return
        #         return
        #     reader.readAsDataURL(blob)
        #     @remove()
        #     return
        
        @resizePlane: ()=>
            # Make sure image is loaded and has dimensions
            if@texture.image and @texture.image.naturalWidth > 0 and @texture.image.naturalHeight > 0
                # Note: must multiply by two to have real size ; but here we want to get half the size
                # newPlaneGeometry = new THREE.PlaneGeometry(texture.image.naturalWidth / window.innerWidth, texture.image.naturalHeight / window.innerHeight)
                ts = Math.min(window.innerWidth, window.innerHeight) # @threeSize
                newPlaneGeometry = new THREE.PlaneGeometry(texture.image.naturalWidth / ts, texture.image.naturalHeight / ts)
                geometry.vertices = newPlaneGeometry.vertices;
                geometry.verticesNeedUpdate = true;
            return

        @onWindowResize: ()=>
            threeWidth = window.innerWidth
            threeHeight = window.innerHeight
            # threeWidth = @threeSize
            # threeHeight = @threeSize
            minDimension = Math.min(threeWidth, threeHeight)
            @renderer.setSize(minDimension, minDimension)
            @effectComposer.setSize(minDimension, minDimension)
            @resizePlane()
            return
        
        @animate: (timestamp = 0)=>
            if @renderer?
                requestAnimationFrame(@animate)
                @effectComposer.render()
            return
        
        @remove: ()=>
            if @stream?
                @stream.getTracks().forEach( (track)-> track.stop() )
            window.removeEventListener("resize", @onWindowResize, false)
            $('#camera').hide()
            $(@renderer.domElement).remove()
            # $(@gui.domElement).remove()
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
            # @paletteShaderPass = null
            return

		constructor: ()->
			return
		
	return Camera
