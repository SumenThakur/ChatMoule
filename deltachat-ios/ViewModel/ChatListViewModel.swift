import UIKit

protocol ChatListViewModelProtocol: class, UISearchResultsUpdating {

    var onChatListUpdate: VoidFunction? { get set }

    var isArchive: Bool { get }

    var numberOfSections: Int { get }
    func numberOfRowsIn(section: Int) -> Int
    func cellDataFor(section: Int, row: Int) -> AvatarCellViewModel

    func msgIdFor(row: Int) -> Int?
    func chatIdFor(section: Int, row: Int) -> Int? // to differentiate betweeen deaddrop / archive / default
    // search related
    var searchActive: Bool { get }
    func beginFiltering()
    func endFiltering()
    func titleForHeaderIn(section: Int) -> String?

    /// returns ROW of table
    func deleteChat(chatId: Int) -> Int
    func archiveChat(chatId: Int)
    func pinChat(chatId: Int)
    func refreshData()

    var numberOfArchivedChats: Int { get }
}

class ChatListViewModel: NSObject, ChatListViewModelProtocol {

    var onChatListUpdate: VoidFunction?

    enum ChatListSectionType {
        case chats
        case contacts
        case messages
    }

    class ChatListSection {
        let type: ChatListSectionType
        var title: String {
            switch type {
            case .chats:
                return String.localized("pref_chats")
            case .contacts:
                return String.localized("contacts_headline")
            case .messages:
                return String.localized("pref_messages")
            }
        }
        var cellData: [AvatarCellViewModel] = []
        init(type: ChatListSectionType) {
            self.type = type
        }
    }

    var isArchive: Bool
    private let dcContext: DcContext

    var searchActive: Bool = false

    private var chatList: DcChatlist!

    // for search filtering
    var filteredChats: ChatListSection = ChatListSection(type: .chats)
    var filteredContacts: ChatListSection = ChatListSection(type: .contacts)
    var filteredMessages: ChatListSection = ChatListSection(type: .messages)

    private var searchResultSections: [ChatListSection] {
        return [filteredChats, filteredContacts, filteredMessages]
            .filter { !$0.cellData.isEmpty } //
    }

    init(dcContext: DcContext, isArchive: Bool) {
        dcContext.updateDeviceChats()
        self.isArchive = isArchive
        self.dcContext = dcContext
        super.init()
        updateChatList(notifyListener: true)
    }

    private func updateChatList(notifyListener: Bool) {
        var gclFlags: Int32 = 0
        if isArchive {
            gclFlags |= DC_GCL_ARCHIVED_ONLY
        }
        self.chatList = dcContext.getChatlist(flags: gclFlags, queryString: nil, queryId: 0)
        if notifyListener {
            onChatListUpdate?()
        }
    }

    var numberOfSections: Int {
        return 1
    }

    func numberOfRowsIn(section: Int) -> Int {
        return chatList.length
    }

    func cellDataFor(section: Int, row: Int) -> AvatarCellViewModel {
        let chatId = chatList.getChatId(index: row)
        let summary = chatList.getSummary(index: row)
        let unreadMessages = dcContext.getUnreadMessages(chatId: chatId)
        let viewModel = ChatCellViewModel(
            chatData: ChatCellData(
                chatId: chatId,
                summary: summary,
                unreadMessages: unreadMessages
            )
        )
        return viewModel
    }

    func titleForHeaderIn(section: Int) -> String? {
        if searchActive {
            return searchResultSections[section].title
        }
        return nil
    }

    func chatIdFor(section: Int, row: Int) -> Int? {
        let cellData = cellDataFor(section: section, row: row)
        switch cellData.type {
        case .CHAT(let data):
            return data.chatId
        case .CONTACT:
            return nil
        }
    }

    func msgIdFor(row: Int) -> Int? {
        if searchActive {
            return nil
        }
        return chatList.getMsgId(index: row)
    }

    func refreshData() {
        updateChatList(notifyListener: true)
    }

    func beginFiltering() {
        searchActive = true
    }

    func endFiltering() {
        searchActive = false
    }

    func deleteChat(chatId: Int) -> Int {

        // find index of chatId
        let indexToDelete = Array(0..<chatList.length).filter { chatList.getChatId(index: $0) == chatId }.first
        dcContext.deleteChat(chatId: chatId)
        updateChatList(notifyListener: false)
        safe_assert(indexToDelete != nil)
        return indexToDelete ?? -1
    }

    func archiveChat(chatId: Int) {
        dcContext.archiveChat(chatId: chatId, archive: !self.isArchive)
        updateChatList(notifyListener: false)
    }

    func pinChat(chatId: Int) {
        let chat = DcChat(id: chatId)
        let pinned = chat.visibility==DC_CHAT_VISIBILITY_PINNED
        self.dcContext.setChatVisibility(chatId: chatId, visibility: pinned ? DC_CHAT_VISIBILITY_NORMAL : DC_CHAT_VISIBILITY_PINNED)
        updateChatList(notifyListener: false)
    }

    var numberOfArchivedChats: Int {
        let chatList = dcContext.getChatlist(flags: DC_GCL_ARCHIVED_ONLY, queryString: nil, queryId: 0)
        return chatList.length
    }

}

// MARK: UISearchResultUpdating
extension ChatListViewModel: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text {
            filterContentForSearchText(searchText)
        }
    }

    private func filterContentForSearchText(_ text: String) {

    }


}

