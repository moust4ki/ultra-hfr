import Testing
@testable import HFRKit

@Suite("Liens chiffrés")
struct CryptLinkTests {
    @Test func decodesAQuoteLink() throws {
        let token = "1F4E43C2C24A4C4319C045C02F424F4944464C2E4544C11946494214424ACB2E2A14C04FC2CB2E2A20242A2421261449C34EC143C02E2A2A2B20242A202C14C143442E2A14C04A4C432E22232014C02E2A14C2C341424ACB2E2A202614C24F494B4A4C432E20144FCC49CB4FC046422E20144943CC2E2012444FC14EC3484A46C143"
        let link = try #require(CryptLink.decode(token))
        #expect(link.hasPrefix("/message.php?config=hfr.inc"))
        #expect(link.contains("post=1061629"))
    }

    @Test func rejectsOtherClassNames() {
        #expect(CryptLink.decode("md_noclass") == nil)
        #expect(CryptLink.decode("XYZ1") == nil)
    }
}
