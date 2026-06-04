FROM mcr.microsoft.com/powershell:lts-7.4-alpine-3.20

RUN pwsh -Command 'Set-PSRepository PSGallery -InstallationPolicy Trusted; Install-Module VenafiPS -ErrorAction Stop'

ENV VDC_SERVER=${VDC_SERVER}
ENV VDC_TOKEN=${VDC_TOKEN}
ENV VC_KEY=${VC_KEY}
ENV POWERSHELL_TELEMETRY_OPTOUT=1

SHELL ["pwsh"]
