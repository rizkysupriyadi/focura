import Foundation
import Testing
@testable import FocuraIOS

struct TimerDurationSelectionTests {
    @Test
    func selectionStartsAtConfiguredDuration() {
        let selection = TimerDurationSelection(configuredMinutes: 25)

        #expect(selection.configuredMinutes == 25)
        #expect(selection.selectedMinutes == 25)
        #expect(selection.usesCustom == false)
    }

    @Test
    func configuredDurationIsClampedToSupportedRange() {
        let low = TimerDurationSelection(configuredMinutes: 0)
        let high = TimerDurationSelection(configuredMinutes: 999)

        #expect(low.configuredMinutes == 1)
        #expect(low.selectedMinutes == 1)
        #expect(high.configuredMinutes == 180)
        #expect(high.selectedMinutes == 180)
    }

    @Test
    func selectingPresetDisablesCustomMode() {
        var selection = TimerDurationSelection(configuredMinutes: 25)

        selection.selectCustom(37)

        #expect(selection.selectedMinutes == 37)
        #expect(selection.usesCustom == true)

        selection.selectPreset(50)

        #expect(selection.selectedMinutes == 50)
        #expect(selection.usesCustom == false)
    }

    @Test
    func customDurationIsClampedToOneHundredEightyMinutes() {
        var selection = TimerDurationSelection(configuredMinutes: 25)

        selection.selectCustom(999)

        #expect(selection.selectedMinutes == 180)
        #expect(selection.usesCustom == true)

        selection.updateCustom(0)

        #expect(selection.selectedMinutes == 1)
    }

    @Test
    func customUpdatesDoNotAffectPresetMode() {
        var selection = TimerDurationSelection(configuredMinutes: 25)

        selection.updateCustom(45)

        #expect(selection.selectedMinutes == 25)
        #expect(selection.usesCustom == false)
    }

    @Test
    func focusAndRelaxSelectionsCanRemainIndependent() {
        var focus = TimerDurationSelection(configuredMinutes: 25)
        var relax = TimerDurationSelection(configuredMinutes: 10)

        focus.selectPreset(50)
        relax.selectCustom(37)

        #expect(focus.selectedMinutes == 50)
        #expect(focus.usesCustom == false)
        #expect(relax.selectedMinutes == 37)
        #expect(relax.usesCustom == true)
    }

    @Test
    func selectionCanBeEncodedAndRestored() throws {
        var original = TimerDurationSelection(configuredMinutes: 25)

        original.selectCustom(42)

        let data = try JSONEncoder().encode(original)

        let restored = try JSONDecoder().decode(
            TimerDurationSelection.self,
            from: data
        )

        #expect(restored == original)
    }
}
