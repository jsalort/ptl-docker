intel:
	docker build --platform x86_64 -t jsalort/ptl .

arm:
	docker build --platform arm64 -t jsalort/ptl .

push:
	docker push jsalort/ptl
