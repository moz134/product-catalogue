import Foundation
import Testing
@testable import Catalogue

@MainActor
struct HomeViewModelTests {
    @Test func loadsTheFiveFeaturedProductsAndTheCategories() async {
        let api = FakeCatalogueAPI()
        let model = HomeViewModel(api: api)

        await model.load()

        #expect(model.featured.value?.map(\.id) == ["1", "2", "3", "4", "5"])
        #expect(model.categories.value?.map(\.slug) == ["electronics", "jewelery"])
    }

    @Test func showsAnErrorWhenFeaturedProductsFailAndRecoversOnRetry() async {
        let api = FakeCatalogueAPI()
        await api.set(featured: .failure(.server(status: 502, code: "UPSTREAM_UNAVAILABLE", message: "Down")))
        let model = HomeViewModel(api: api)

        await model.load()
        #expect(model.featured.error == .server(status: 502, code: "UPSTREAM_UNAVAILABLE", message: "Down"))
        #expect(model.categories.value?.count == 2, "categories still load when featured fails")

        await api.set(featured: .success(Sample.products))
        await model.loadFeatured()
        #expect(model.featured.value?.count == 5)
    }

    @Test func searchTermIsTrimmedAndBlankSearchesAreIgnored() {
        let model = HomeViewModel(api: FakeCatalogueAPI())

        model.searchText = "   "
        #expect(model.submittedSearchTerm() == nil)

        model.searchText = "  ssd drive "
        #expect(model.submittedSearchTerm() == "ssd drive")
    }

    @Test func typingDoesNotSearch() async {
        let api = FakeCatalogueAPI()
        let model = HomeViewModel(api: api)

        model.searchText = "ssd"

        #expect(await api.calls.contains { $0.hasPrefix("search") } == false)
    }
}

@MainActor
struct CategoryViewModelTests {
    @Test func loadsTopRatedAndOtherProductsForTheCategory() async {
        let api = FakeCatalogueAPI()
        let model = CategoryViewModel(api: api, category: Sample.electronics)

        await model.load()

        #expect(await api.calls == ["categoryPage:electronics"])
        #expect(model.page.value?.topRated.map(\.id) == ["1", "2"])
        #expect(model.page.value?.others.map(\.id) == ["3"])
    }

    @Test func aFailedRefreshShowsTheErrorWithRetry() async {
        let api = FakeCatalogueAPI()
        let model = CategoryViewModel(api: api, category: Sample.electronics)
        await model.load()

        await api.set(categoryPage: .failure(.network))
        await model.load()

        #expect(model.page.error == .network)
    }
}

@MainActor
struct SearchViewModelTests {
    @Test func searchesForTheSubmittedTerm() async {
        let api = FakeCatalogueAPI()
        let model = SearchViewModel(api: api, term: "ssd")

        await model.load()

        #expect(await api.calls == ["search:ssd"])
        #expect(model.results.value?.map(\.id) == ["2"])
    }
}

@MainActor
struct ProductDetailViewModelTests {
    @Test func loadsTheProduct() async {
        let api = FakeCatalogueAPI()
        let model = ProductDetailViewModel(api: api, productID: "1")

        await model.load()

        #expect(await api.calls == ["product:1"])
        #expect(model.product.value?.title == "Product 1")
    }

    @Test func reportsNotFound() async {
        let api = FakeCatalogueAPI()
        await api.set(product: .failure(.notFound))
        let model = ProductDetailViewModel(api: api, productID: "999")

        await model.load()

        #expect(model.product.error == .notFound)
    }
}
