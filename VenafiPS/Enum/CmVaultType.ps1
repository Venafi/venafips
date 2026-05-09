enum CmVaultType {
    None = 0;

    # Standard types
    PrivateKey = 1;
    Certificate = 2;
    PKCS12 = 4;
    SymmetricKey = 8;
    State = 16;
    Password = 32;
    Csr = 64;
    Blob = 128;
    PKCS8 = 256;
    PKCS10 = 512;
    File = 1024;
    RSAPublicKey = 2048;
    PublicKey = 4096;
    AccessGrant = 8192;
    SshCertificate = 16384;

    # Archived types (Archived overlay = 1073741824)
    Archived = 1073741824;
    ArchivedCertificate = 1073741826;      # Certificate + Archived
    ArchivedPKCS12 = 1073741828;           # PKCS12 + Archived
    ArchivedSymmetricKey = 1073741832;     # SymmetricKey + Archived
    ArchivedState = 1073741840;            # State + Archived
    ArchivedPassword = 1073741856;         # Password + Archived
    ArchivedBlob = 1073741952;             # Blob + Archived
    ArchivedPKCS8 = 1073742080;            # PKCS8 + Archived
    ArchivedPKCS10 = 1073742336;           # PKCS10 + Archived
    ArchivedFile = 1073742848;             # File + Archived
    ArchivedRSAPublicKey = 1073743872;     # RSAPublicKey + Archived
    ArchivedPublicKey = 1073745920;        # PublicKey + Archived
    ArchivedSshCertificate = 1073758208;   # SshCertificate + Archived

    # Refigram types (Refigram overlay = -2147483648)
    Refigram = -2147483648;
    RefigramPKCS8 = -2147483392;           # PKCS8 + Refigram
    RefigramPublicKey = -2147479552;       # PublicKey + Refigram
    RefigramSymmetricKey = -2147483640;    # SymmetricKey + Refigram

    # Archived Refigram types
    ArchivedRefigramPKCS8 = -1073741568;          # RefigramPKCS8 + Archived
    ArchivedRefigramPublicKey = -1073737728;      # RefigramPublicKey + Archived
    ArchivedRefigramSymmetricKey = -1073741816;   # RefigramSymmetricKey + Archived
}