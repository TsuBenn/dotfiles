package manager;

/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */

/**
 *
 * @author Admin
 */
import model.Member;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

public class MemberManager {
    // Attributes
    private List<Member> members;

    public List<Member> getAllMembers() {
        return members;
    }

    // Constructor
    public MemberManager() {
        this.members = new ArrayList<>();
    }

    // +addMember(Member member) : void
    public void addMember(Member member) {
        if (member != null) {
            members.add(member);
        }
    }

    // +getMemberById(String memberId) : Member
    public Member getMemberById(String memberId) {
        try {
            UUID id = UUID.fromString(memberId);
            for (Member m : members) {
                if (m.getMemberId().equals(id)) {
                    return m;
                }
            }
        } catch (IllegalArgumentException e) {
            System.out.println("Invalid UUID string format.");
        }
        return null; // Return null if member not found
    }

    // +updateMember(String memberId, Member updatedMember) : boolean
    public boolean updateMember(String memberId, Member updatedMember) {
        Member existingMember = getMemberById(memberId);
        if (existingMember != null && updatedMember != null) {
            existingMember.setInfo(updatedMember.getInfo());
            existingMember.setBorrowLimit(updatedMember.getBorrowLimit());
            existingMember.setFineMoney(updatedMember.getFineMoney());
            existingMember.setBorrowedBooks(updatedMember.getBorrowedBooks());
            return true;
        }
        return false;
    }

    // +deleteMember(String memberId) : boolean
    public boolean deleteMember(String memberId) {
        Member member = getMemberById(memberId);
        if (member != null) {
            return members.remove(member);
        }
        return false;
    }

    // +findMembersByName(String name) : List<Member>
    // Note: Since 'name' isn't explicitly an attribute on Member, 
    // we assume it is checked against a field inside ContactInformation.
    public List<Member> findMembersByName(String name) {
        List<Member> result = new ArrayList<>();
        for (Member m : members) {
            if (m.getInfo() != null && m.getInfo().getName() != null 
                    && m.getInfo().getName().equalsIgnoreCase(name)) {
                result.add(m);
            }
        }
        return result;
    }
}