import UIKit
import DcCore

class BlockedContactsViewController: GroupMembersViewController, GroupMemberSelectionDelegate {

    var emptyStateView: EmptyStateLabel = {
        let view =  EmptyStateLabel()
        view.text = String.localized("none_blocked_desktop")
        return view
    }()

    override init() {
        super.init()
        enableCheckmarks = false
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = String.localized("pref_blocked_contacts")
        contactIds = dcContext.getBlockedContacts()
        selectedContactIds = Set(contactIds)
        navigationItem.searchController = nil
        groupMemberSelectionDelegate = self
        setupSubviews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateEmtpyStateView()
    }

    // MARK: - setup
    private func setupSubviews() {
        view.addSubview(emptyStateView)
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true
        emptyStateView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40).isActive = true
        emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40).isActive = true
    }

    // MARK: - actions + updates
    func selected(contactId: Int, selected: Bool) {
        if !selected {
            let dcContact = DcContact(id: contactId)
            let title = dcContact.displayName.isEmpty ? dcContact.email : dcContact.displayName
            let alert = UIAlertController(title: title, message: String.localized("ask_unblock_contact"), preferredStyle: .safeActionSheet)
            alert.addAction(UIAlertAction(title: String.localized("menu_unblock_contact"), style: .default, handler: { _ in
                let contact = DcContact(id: contactId)
                contact.unblock()
                self.contactIds = self.dcContext.getBlockedContacts()
                self.selectedContactIds = Set(self.contactIds)
                self.tableView.reloadData()
                self.updateEmtpyStateView()
            }))
            alert.addAction(UIAlertAction(title: String.localized("cancel"), style: .cancel, handler: { _ in
                self.selectedContactIds = Set(self.contactIds)
                self.tableView.reloadData()
            }))
           present(alert, animated: true, completion: nil)
        }
    }

    private func updateEmtpyStateView() {
        emptyStateView.isHidden = super.numberOfRowsForContactList > 0
    }
}
