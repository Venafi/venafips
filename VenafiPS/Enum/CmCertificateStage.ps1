enum CmCertificateStage {
    CheckStore = 100
    CreateConfigureStore = 200
    CreateKey = 300
    CreateCSR = 400
    PostCSR = 500
    ApproveRequest = 600
    RetrieveCertificate = 700
    InstallCertificate = 800
    CheckConfiguration = 900
    ConfigureApplication = 1000
    RestartApplication = 1100
    EndProcessing = 1200
    Revocation = 1400
    UpdateTrustStore = 1500
    EndTrustStoreProcessing = 1600
}
