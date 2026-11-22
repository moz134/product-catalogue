import Foundation
import Testing
@testable import Catalogue

struct AppConfigTests {
    @Test func environmentVariableOverridesTheDefault() {
        let url = AppConfig.apiBaseURL(environment: ["CATALOGUE_API_BASE_URL": "http://192.168.1.20:3000/api/v1"])
        #expect(url.absoluteString == "http://192.168.1.20:3000/api/v1")
    }

    @Test func fallsBackToInfoPlistWhenTheVariableIsMissingOrInvalid() {
        #expect(AppConfig.apiBaseURL(environment: [:]).absoluteString == "http://localhost:3000/api/v1")
        #expect(AppConfig.apiBaseURL(environment: ["CATALOGUE_API_BASE_URL": "not a url"]).absoluteString == "http://localhost:3000/api/v1")
    }

    @Test func uiTestLaunchArgumentSelectsTheStubAPI() {
        #expect(AppDependencies.makeAPI(arguments: [AppDependencies.stubLaunchArgument]) is StubCatalogueAPI)
        #expect(AppDependencies.makeAPI(arguments: []) is HTTPCatalogueAPI)
    }
}
